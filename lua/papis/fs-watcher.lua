--
-- PAPIS | FS-WATCHER
--
--
-- Watches the system for updated library files.
--
-- Adapted from: https://github.com/rktjmp/fwatch.nvim
--

local Path = require("pathlib")

local uv = vim.uv
local fs_stat = uv.fs_stat
local new_timer = uv.new_timer
local api = vim.api
local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")
local log = require("papis.log")
local does_pid_exist = require("papis.utils").does_pid_exist
local data = assert(require("papis.data"), "Failed to load papis.data")
local file_read_timer
local autocmd_id
local handles = {}
local fs_watching_stopped = false
local event_timestamps = {}

---Uses libuv to start file system watchers
---@param path string #The path to watch
---@param on_event function #Function to run on file system event
---@param on_error function #Function to run on error
local function do_watch(path, on_event, on_error)
  local handle = uv.new_fs_event()
  if not handle then
    return
  end
  local unwatch_cb = function()
    handle:stop()
  end
  local event_cb = function(err, filename)
    if err then
      on_error(error, unwatch_cb)
    else
      on_event(filename, unwatch_cb)
    end
  end
  handle:start(tostring(path), {}, event_cb)
  handles[#handles + 1] = handle
end

---Gets all directories in the library_dir
---@return table #A list of all directories in library_dir
local function get_library_dirs()
  local library_dir = Path(db.config:get_conf_value("dir"))
  local library_dirs = {}
  for path in library_dir:fs_iterdir() do
    library_dirs[#library_dirs + 1] = path
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
    local info_name = db.config:get_conf_value("info_name")
    local mtime
    local entry_dir
    local info_path
    local do_unwatch = false
    local do_update = true
    local current_time = uv.hrtime() / 1e6 -- get current time in milliseconds
    local last_event_time = event_timestamps[filename]

    if last_event_time and current_time - last_event_time < 200 then
      log.debug("Debouncing: skipping filesystem event")
      -- If the last event for this file was less than 200ms ago, discard this event
      return
    end

    -- Update the timestamp for this file
    event_timestamps[filename] = current_time

    vim.defer_fn(function()
      if is_library_root then
        log.debug("Filesystem event in the library root directory")
        entry_dir = Path(dir_to_watch, filename)
        info_path = entry_dir / info_name
        local entry_dir_str = tostring(entry_dir)
        local info_path_str = tostring(info_path)
        if entry_dir:exists() and entry_dir:is_dir() then
          log.debug(string.format("Filesystem event: path '%s' added", entry_dir_str))
          init_fs_watcher(entry_dir_str)
          if info_path:exists() then
            mtime = fs_stat(info_path_str).mtime.sec
          end
        elseif entry_dir:is_dir() then
          log.debug(string.format("Filesystem event: path '' removed", entry_dir_str))
          -- don't update here, because we'll catch it below under entry events
          do_update = false
        else
          -- it's a file (not a directory). ignore
          do_update = false
        end
      else
        log.debug("Filesystem event in entry directory")
        entry_dir = Path(dir_to_watch)
        info_path = entry_dir / info_name
        local info_path_str = tostring(info_path)
        if info_path:exists() then
          -- info file exists, update with new info
          log.debug(string.format("Filesystem event: '%s' changed", info_path_str))
          mtime = fs_stat(tostring(info_path)).mtime.sec
        elseif not entry_dir:exists() then
          -- info file and entry dir don't exist. delete entry (mtime = nil) and remove watcher
          log.debug(string.format("Filesystem event: '%s' removed", info_path_str))
          do_unwatch = true
        else
          -- info file doesn't exist but entry dir does. delete entry but keep watcher
          log.debug(string.format("Filesystem event: '%s' removed", info_path_str))
        end
      end
      if do_update then
        local info_path_str = tostring(info_path)
        log.debug("Update database for this fs event...")
        log.debug("Updating: " .. vim.inspect({ path = info_path_str, mtime = mtime }))
        data.update_db({ path = info_path_str, mtime = mtime })
      elseif do_unwatch then
        log.debug("Removing watcher")
        unwatch_cb()
      end
    end, 200)
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
    vim.notify(string.format("An error occured: %s", error), vim.log.levels.ERROR)
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
  local library_dir = Path(db.config:get_conf_value("dir"))
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
    assert(file_read_timer, "Failed to create libuv timer")
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
        log.debug("Start autocmd to unset db state if this instance stops fs watchers")
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
    log.debug("Start autocmd to unset db state if this instance stops fs watchers")
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
      handle:stop()
    end
    handles = {}
    db.state:set_fw_running()
  end
  fs_watching_stopped = true
end

return M
