--
-- PAPIS | INIT
--
--
-- Sets up papis.nvim.
--

local config = require("papis.config")
local api = vim.api
local log

---Creates the `autocmd` that starts papis.nvim when configured conditions are fulfilled
local function make_start_autocmd()
  local load_papis = api.nvim_create_augroup("loadPapis", { clear = true })
  api.nvim_create_autocmd("FileType", {
    once = true,
    pattern = config["init_filetypes"],
    callback = require("papis").start,
    group = load_papis,
    desc = "Load papis.nvim for defined filetypes",
  })
end

---Checks whether dependencies are available
local function are_dependencies_available()
  local dependencies = { "papis", config["yq_bin"] }
  for _, dependency in ipairs(dependencies) do
    if vim.fn.executable(dependency) == 0 then
      log.error(
        string.format("The executable '%s' could not be found. Please install it to use papis.nvim", dependency)
      )
      return false
    end
  end
  return true
end

local M = {}

---This function is run when neovim starts and sets up papis.nvim.
---@param opts table #User configuration
function M.setup(opts)
  -- update config with user config
  config:update(opts)

  -- create autocmd that starts papis.nvim for configured filetypes
  make_start_autocmd()
end

---This function starts all of papis.nvim.
function M.start()
  log = require("papis.log")
  log.new(config["log"] or log.get_default_config(), true)
  log.debug("_________________________STARTING PAPIS.NVIM_________________________")

  -- ensure that config options from Papis (python app) are setup
  config:setup_papis_py_conf()

  if not are_dependencies_available() then
    return nil
  end

  -- require what's necessary within `M.start()` instead of globally to allow lazy-loading
  local db = require("papis.sqlite-wrapper")
  if not db then
    log.warn("Requiring `sqlite-wrapper.lua` failed. Aborting...")
    return nil
  end
  local data = require("papis.data")
  if not data then
    log.warn("Requiring `data.lua` failed. Aborting...")
    return nil
  end

  -- setup commands
  require("papis.commands").setup()
  -- setup keymaps
  require("papis.keymaps"):setup()

  -- setup enabled modules
  for module_name, _ in pairs(config["enable_modules"]) do
    log.trace(module_name .. " is enabled")
    local has_module, module = pcall(require, "papis." .. module_name)
    if has_module then
      if module["setup"] then
        module.setup()
      end
    end
  end

  -- check if other neovim instances has file watchers
  local does_pid_exist = require("papis.utils").does_pid_exist
  if not does_pid_exist(db.state:get_fw_running()) then
    -- setup file watchers (or an autocmd if another instance has file watchers)
    if config["enable_fs_watcher"] then
      require("papis.fs-watcher"):init()
    end

    log.debug("Synchronising the database")
    data:sync_db()
  else
    -- setup file watchers (or an autocmd if another instance has file watchers)
    if config["enable_fs_watcher"] then
      require("papis.fs-watcher"):init()
    end
  end

  log.debug("Papis.nvim up and running")
end

return M
