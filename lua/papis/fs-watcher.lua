--
-- PAPIS | FS-WATCHER
--
--
-- Watches the system for updated library files.
--
-- Adapted from: https://github.com/rktjmp/fwatch.nvim
--

local Path = require("pathlib")

local uv = vim.loop
local fs_stat = uv.fs_stat
local new_timer = uv.new_timer
local api = vim.api
local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end
local log = require("papis.logger")
local does_pid_exist = require("papis.utils").does_pid_exist
local data = require("papis.data")
if not data then
  return nil
end
local file_read_timer
local autocmd_id
local handles = {}
local fs_watching_stopped = false

---Uses libuv to start file system watchers
---@param path string #The path to watch
---@param on_event function #Function to run on file system event
---@param on_error function #Function to run on error
local function do_watch(path, on_event, on_error)
  local handle = uv.new_fs_event()
  local unwatch_cb = function()
    uv.fs_event_stop(handle)
  end
  local event_cb = function(err, filename)
    if err then
      on_error(error, unwatch_cb)
    else
      on_event(filename, unwatch_cb)
    end
  end
  uv.fs_event_start(handle, tostring(path), {}, event_cb)
  table.insert(handles, handle)
end

---Gets all directories in the library_dir
---@return table #A list of all directories in library_dir
local function get_library_dirs()
  local library_dir = Path(db.config:get_value({ id = 1 }, "dir"))
  local library_dirs = {}
  for path in library_dir:fs_iterdir() do
    table.insert(library_dirs, path)
  end
  return library_dirs
end

---Initialises file system watchers for papis.nvim
---@param dir_to_watch string #The directory to watch
---@param is_library_root? boolean #True if the supplied directory is the library root directory
local function init_fs_watcher(dir_to_watch, is_library_root)
  is_library_root = is_library_root or false

  ---Runs on every file system event and starts the appropriate papis.nvim functions
  ---@param filename string #The name of the file that triggered the event
  ---@param unwatch_cb function #The callback that stops a watcher
  local function do_handle_event(filename, unwatch_cb)
    local info_name = db.config:get_value({ id = 1 }, "info_name")
    local mtime
    local entry_dir
    local info_path
    local do_unwatch = false
    local do_update = true
    if is_library_root then
      log.debug("Filesystem event in the library root directory")
      entry_dir = Path(dir_to_watch, filename)
      info_path = entry_dir:joinpath(info_name)
      if entry_dir:exists() and entry_dir:is_dir() then
        log.debug(string.format("Filesystem event: path '%s' added", entry_dir:absolute()))
        init_fs_watcher(entry_dir:absolute())
        if info_path:exists() then
          mtime = fs_stat(info_path:absolute()).mtime.sec
        end
      elseif entry_dir:is_dir() then
        log.debug(string.format("Filesystem event: path '' removed", entry_dir:absolute()))
        -- don't update here, because we'll catch it below under entry events
        do_update = false
      else
        -- it's a file (not a directory). ignore
        do_update = false
      end
    else
      log.debug("Filesystem event in entry directory")
      entry_dir = Path(dir_to_watch)
      info_path = entry_dir:joinpath(info_name)
      if info_path:exists() then
        -- info file exists, update with new info
        log.debug(string.format("Filesystem event: '%s' changed", info_path:absolute()))
        mtime = fs_stat(info_path:absolute()).mtime.sec
      elseif not entry_dir:exists() then
        -- info file and entry dir don't exist. delete entry (mtime = nil) and remove watcher
        log.debug(string.format("Filesystem event: '%s' removed", info_path:absolute()))
        do_unwatch = true
      else
        -- info file doesn't exist but entry dir does. delete entry but keep watcher
        log.debug(string.format("Filesystem event: '%s' removed", info_path:absolute()))
      end
    end
    if do_update then
      log.debug("Update database for this fs event...")
      log.debug("Updating: " .. vim.inspect({ path = info_path:absolute(), mtime = mtime }))
      vim.defer_fn(function()
        data.update_db({ path = info_path:absolute(), mtime = mtime })
      end, 200)
    elseif do_unwatch then
      log.debug("Removing watcher")
      unwatch_cb()
    end
  end

  -- start the file watcher
  do_watch(dir_to_watch, function(filename, unwatch_cb)
    log.debug(string.format("Filesystem event detected: %s", filename))
    log.debug("Executing function on file system event")
    do_handle_event(filename, unwatch_cb)
  end, function(error, unwatch_cb)
    -- disable watcher
    unwatch_cb()
    -- note, print still occurs even though we unwatched *future* events
    log.warn(string.format("An error occured: %s", error))
  end)
end

---Sets up an autocmd to change fw_running in database to nil when this neovim instance quits
local function init_autocmd()
  local unsetPapisWatcherState = api.nvim_create_augroup("unsetPapisWatcherState", { clear = true })

  autocmd_id = api.nvim_create_autocmd("ExitPre", {
    pattern = "*",
    callback = function()
      log.debug("Unset db state to indicate fswatcher is inactive")
      db.state:set_fw_running()
    end,
    group = unsetPapisWatcherState,
    desc = "Unset papis.nvim file watcher state in database.",
  })
end

---Starts file system watchers for root dir and all entry dirs
local function start_fs_watchers()
  log.debug("Set db state to indicate fswatcher is active")
  local library_dir = Path(db.config:get_value({ id = 1 }, "dir"))
  db.state:set_fw_running(uv.os_getpid())

  log.debug("Setting up fswatcher for library root directory")
  init_fs_watcher(library_dir, true)

  log.debug("Setting up fswatcher for each entry directory")
  for _, dir in ipairs(get_library_dirs()) do
    init_fs_watcher(dir)
  end
end

---Start a timer to periodically check if other neovim instance has stopped file watchers
local function start_fs_watch_active_timer()
  log.debug("Timer started to check if need to take over fswatch")
  if not file_read_timer then
    file_read_timer = new_timer()
  end
  uv.timer_start(
    file_read_timer,
    0,
    10000,
    vim.schedule_wrap(function()
      if not does_pid_exist(db.state:get_fw_running()) then
        log.debug("Taking over file system watching duties")
        data:sync_db()
        start_fs_watchers()
        log.debug("Start autocmd lo unset db state if this instance stops fs watchers")
        init_autocmd()
      end
    end)
  )
end

local M = {}

---Sets up the fs-watcher module
function M:init()
  log.debug("Fs-watcher: setting up module")
  if fs_watching_stopped == false then
    self.start()
  end
end

---Starts file watchers and the timer that takes over file watching duty
function M.start()
  if not does_pid_exist(db.state:get_fw_running()) then
    log.debug("Starting file watchers")
    start_fs_watchers()
    log.debug("Start autocmd lo unset db state if this instance stops fs watchers")
    init_autocmd()
  else
    log.debug("This neovim instance will take over file watching if required")
    start_fs_watch_active_timer()
  end
  fs_watching_stopped = false
end

---Stops file watchers and the autocmd that takes over file watching duty
function M.stop()
  log.debug("This neovim instance will no longer watch for file changes")
  if file_read_timer then
    log.trace("Stopping the fs watcher timer")
    uv.timer_stop(file_read_timer)
  end
  if autocmd_id then
    log.trace("Removing the fs-watcher autocmd")
    api.nvim_del_autocmd(autocmd_id)
  end
  if not vim.tbl_isempty(handles) then
    log.trace("Stopping the fs watchers")
    for _, handle in ipairs(handles) do
      uv.fs_event_stop(handle)
    end
    handles = {}
    db.state:set_fw_running()
  end
  fs_watching_stopped = true
end

return M
