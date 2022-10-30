--
-- PAPIS | LOGGER
--
--
-- Manages logging and messages to the user
--
-- Adapted from https://github.com/jose-elias-alvarez/null-ls.nvim
--

local log = require("plenary.log")
local Path = require("plenary.path")

local log_config = require("papis.config")["log"]

-- default options used when calling vim.notify
local default_notify_opts = {
	title = "papis",
}

local notify_fmt, handle

local M = {}

---Adds a log entry using Plenary.log
---@param msg string #The message to be logged
---@param level string #The log level, one of vim.log.levels
local function add_entry(msg, level)
	if not notify_fmt then
		notify_fmt = function(m)
			return string.format(log_config.notify_format, m)
		end
	end

	if log_config.level == "off" then
		return
	end

	if handle then
		handle[level](msg)
		return
	end

	local default_opts = {
		plugin = "papis",
		level = log_config.level,
		use_console = false,
		info_level = 4,
	}

	handle = log.new(default_opts)
	handle[level](msg)
end

---Add a log entry at TRACE level
---@param msg string #The message to be logged
function M.trace(msg)
	add_entry(msg, "trace")
end

---Add a log entry at DEBUG level
---@param msg string #The message to be logged
function M.debug(msg)
	add_entry(msg, "debug")
end

---Add a log entry at INFO level
---@param msg string #The message to be logged
function M.info(msg)
	add_entry(msg, "info")
	vim.notify(notify_fmt(msg), vim.log.levels.INFO, default_notify_opts)
end

---Add a log entry at WARN level
---@param msg string #The message to be logged
function M.warn(msg)
	add_entry(msg, "warn")
	vim.notify(notify_fmt(msg), vim.log.levels.WARN, default_notify_opts)
end

---Add a log entry at ERROR level
---@param msg string #The message to be logged
function M.error(msg)
	add_entry(msg, "error")
	vim.notify(notify_fmt(msg), vim.log.levels.ERROR, default_notify_opts)
end

---Retrieves the path of the logfile
function M.get_path()
	local log_path = Path:new(vim.fn.stdpath("cache"), "papis.log"):absolute()
	vim.notify(log_path)
end

return M
