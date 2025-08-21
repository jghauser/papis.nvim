--
-- PAPIS | INIT
--
--
-- Sets up papis.nvim.
--

local config = require("papis.config")
local api = vim.api
local has_run = false

---Creates the `autocmd` that starts papis.nvim when configured conditions are fulfilled
local function make_start_autocmd()
  local load_papis = api.nvim_create_augroup("loadPapis", { clear = true })
  api.nvim_create_autocmd("FileType", {
    once = true,
    pattern = config.init_filetypes,
    callback = function()
      if not has_run then
        require("papis").start()
      end
    end,
    group = load_papis,
    desc = "Load papis.nvim for defined filetypes",
  })
end

---Checks whether dependencies are available
---@return boolean #True if all dependencies are available, false otherwise
local function are_dependencies_available()
  local dependencies = { "papis", config.yq_bin }
  for _, dependency in ipairs(dependencies) do
    if vim.fn.executable(dependency) == 0 then
      vim.notify(
        string.format("The executable '%s' could not be found. Please install it to use papis.nvim", dependency),
        vim.log.levels.ERROR
      )
      return false
    end
  end
  return true
end

local M = {}

---This function is run when neovim starts and sets up papis.nvim.
---@param opts table User configuration
function M.setup(opts)
  -- update config with user config
  config:update(opts)

  -- create autocmd that starts papis.nvim for configured filetypes
  make_start_autocmd()
end

---This function starts all of papis.nvim.
function M.start()
  local log = require("papis.log")
  log.new(config["log"] or log.get_default_config(), true)
  log.debug("_________________________STARTING PAPIS.NVIM_________________________")

  has_run = true

  -- set up db
  local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")
  db:init()

  -- check for dependencies
  if not are_dependencies_available() then
    return nil
  end

  -- require what's necessary within `M.start()` instead of globally to allow lazy-loading
  local data = assert(require("papis.data"), "Failed to load papis.data")

  -- setup commands
  log.debug("Setting up commands")
  require("papis.commands").setup()

  -- setup enabled modules
  for module_name, _ in pairs(config.enable_modules) do
    log.debug(module_name .. " is enabled")
    local has_module, module = pcall(require, "papis." .. module_name)
    if has_module then
      if module.setup then
        module.setup()
      end
    end
  end

  -- setup keymaps
  log.debug("Setting up keymaps")
  require("papis.keymaps"):setup()

  -- check if other neovim instances has file watchers
  local does_pid_exist = require("papis.utils").does_pid_exist
  if not does_pid_exist(db.state:get_fw_running()) then
    -- setup file watchers because no other neovim instance has them
    if config.enable_fs_watcher then
      log.debug("Setting up file watchers")
      require("papis.fs-watcher"):init()
    end

    -- only synchronise the data table if it's not empty
    -- (in that case, we tell users to manually do it because it takes a while)
    if (db.data:empty() == false) and (db.metadata:empty() == false) then
      log.debug("Setting up/syncronising the database")
      data:sync_db()
    end
  else
    -- setup file watchers (or an autocmd if another instance has file watchers)
    if config.enable_fs_watcher then
      require("papis.fs-watcher"):init()
    end
  end

  log.debug("Papis.nvim up and running")
end

return M
