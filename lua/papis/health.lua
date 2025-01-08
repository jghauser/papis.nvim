--
-- PAPIS | HEALTH
--
--
-- Implements checkhealth funtionality.
--

local Path = require("pathlib")

local uv = vim.uv

local config = require("papis.config")
local utils = require("papis.utils")
local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end
local health

local reports = {}

---Creates a report for the sqlite database
reports["sqlite-wrapper"] = function()
  local sqlite_is_executable = vim.fn.executable("sqlite3")
  local db_exists = Path(config.db_path):exists()
  local db_is_empty = db.data:empty()

  health.start("Sqlite database")
  health.info(string.format("Papis.nvim db location: %s.", config.db_path))
  if sqlite_is_executable then
    health.ok("The 'sqlite3' executable was found in path.")
  else
    health.error("The 'sqlite3' executable was not found in path.")
  end
  if db_exists then
    health.ok("The database exists.")
  else
    health.error("The database does not exist.")
  end
  if db_is_empty then
    health.warn("The database is empty.")
  else
    health.ok("The database isn't empty.")
  end
end

---Creates a report for the file-system watcher
reports["fs-watcher"] = function()
  local pid_in_db = db.state:get_fw_running()
  local current_pid = uv.os_getpid()
  health.start("File watcher")
  if not pid_in_db then
    health.error("No neovim instance is running file watchers.")
  end
  if pid_in_db == current_pid then
    health.ok(string.format("This neovim instance (PID: %s) is running file watchers.", current_pid))
  else
    local pid_exists = utils.does_pid_exist(pid_in_db)
    if pid_exists then
      health.ok(
        string.format(
          "This instance (PID: %s) isn't running file watchers but another (PID: %s) is.",
          current_pid,
          pid_in_db
        )
      )
    elseif pid_in_db then
      health.error(
        string.format(
          "This instance (PID: %s) isn't running file watchers, and while another (PID: %s) should be running file watchers, no process with that PID exists.",
          current_pid,
          pid_in_db
        )
      )
    else
    end
  end
end

---Creates a report for papis-storage
reports["papis-storage"] = function()
  local yq = config.yq_bin
  local yq_is_executable = vim.fn.executable(yq)

  health.start("Papis storage")
  if yq_is_executable then
    health.info(string.format("The '%s' executable was found in path.", yq))
    local yq_version = vim.fn.system(yq .. " --version")
    local is_yq_go = string.find(yq_version, "mikefarah")
    if is_yq_go then
      health.ok(string.format("The go version of the '%s' executable was found in path.", yq))
    else
      health.error(string.format(
        "The python version of the '%s' executable was found in path. However, we need the go version.", yq))
    end
  else
    health.error(string.format("The '%s' executable was not found in path.", yq))
  end
end

---Creates a report for completion
reports["completion"] = function()
  local yaml_parser = vim.api.nvim_get_runtime_file('parser/yaml.so', true)

  health.start("Completion")
  if not vim.tbl_isempty(yaml_parser) then
    health.ok("The treesitter 'yaml' parser was found.")
  else
    health.error("The treesitter 'yaml' parser was not found.")
  end
end

local M = {}

---Main function called by checkhealth
M.check = function()
  if not health then
    health = vim.health
  end

  reports["papis-storage"]()
  reports["sqlite-wrapper"]()
  if config.enable_fs_watcher then
    reports["fs-watcher"]()
  end
  for module_name, _ in pairs(config.enable_modules) do
    if reports[module_name] then
      reports[module_name]()
    end
  end
end

return M
