--
-- PAPIS | HEALTH
--
--
-- Implements checkhealth funtionality.
--

local Path = require("plenary.path")

local uv = vim.loop

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
	local db_exists = Path:new(config["db_path"]):exists()
	local db_is_empty = db.data:empty()

	health.report_start("Sqlite database")
	health.report_info(string.format("Papis.nvim db location: %s.", config["db_path"]))
	if sqlite_is_executable then
		health.report_ok("The 'sqlite3' executable was found in path.")
	else
		health.report_error("The 'sqlite3' executable was not found in path.")
	end
	if db_exists then
		health.report_ok("The database exists.")
	else
		health.report_error("The database does not exist.")
	end
	if db_is_empty then
		health.report_warn("The database is empty.")
	else
		health.report_ok("The database isn't empty.")
	end
end

---Creates a report for the file-system watcher
reports["fs-watcher"] = function()
	local pid_in_db = db.state:get_fw_running()
	local current_pid = uv.os_getpid()
	health.report_start("File watcher")
	if not pid_in_db then
		health.report_error("No neovim instance is running file watchers.")
	end
	if pid_in_db == current_pid then
		health.report_ok(string.format("This neovim instance (PID: %s) is running file watchers.", current_pid))
	else
		local pid_exists = utils.does_pid_exist(pid_in_db)
		if pid_exists then
			health.report_ok(
				string.format(
					"This instance (PID: %s) isn't running file watchers but another (PID: %s) is.",
					current_pid,
					pid_in_db
				)
			)
		elseif pid_in_db then
			health.report_error(
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

local M = {}

---Main function called by checkhealth
M.check = function()
	if not health then
		health = vim.health or require("health")
	end

	reports["sqlite-wrapper"]()
	if config["enable_fs_watcher"] then
		reports["fs-watcher"]()
	end
	for module_name, is_enabled in pairs(config["enable_modules"]) do
		if is_enabled and reports[module_name] then
			reports[module_name]()
		end
	end
end

return M
