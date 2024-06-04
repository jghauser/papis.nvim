--
-- PAPIS | COMMANDS
--
--
-- Sets up default commands.
--

local config = require("papis.config")
local api = vim.api

local commands = {
  ["base"] = {
    reinit_data = {
      name = "PapisReInitData",
      command = function()
        require("papis.data"):reset_db()
      end,
      opts = { desc = "Papis: empty and repopulate the sqlite database from disk" },
    },
    reinit_papis_py_config = {
      name = "PapisReInitConfig",
      command = function()
        local testing_session = config["enable_modules"]["testing"]
        local papis_py_conf_new = config:get_papis_py_conf(testing_session)
        config:compare_papis_py_conf(papis_py_conf_new)
      end,
      opts = { desc = "Papis: import configuration from Papis" },
    },
  },
  ["debug"] = {
    stop_fw = {
      name = "PapisDebugFWStop",
      command = function()
        require("papis.fs-watcher").stop()
      end,
      opts = { desc = "Papis: stop file watching" },
    },
    start_fw = {
      name = "PapisDebugFWStart",
      command = function()
        require("papis.fs-watcher").start()
      end,
      opts = { desc = "Papis: start file watching" },
    },
    get_log_path = {
      name = "PapisDebugGetLogPath",
      command = function()
        require("papis.log").get_path()
      end,
      opts = { desc = "Papis: get path to the log file" },
    },
  },
  ["cursor-actions"] = {
    open_file = {
      name = "PapisOpenFile",
      command = function()
        return require("papis.cursor-actions").open_file()
      end,
      opts = { desc = "Papis: open the files attached to entry under cursor" },
    },
    open_note = {
      name = "PapisOpenNote",
      command = function()
        return require("papis.cursor-actions").open_note()
      end,
      opts = { desc = "Papis: open the note of the entry under cursor" },
    },
    edit_entry = {
      name = "PapisEditEntry",
      command = function()
        return require("papis.cursor-actions").edit_entry()
      end,
      opts = { desc = "Papis: edit the entry under cursor" },
    },
    show_popup = {
      name = "PapisShowPopup",
      command = function()
        return require("papis.cursor-actions").show_popup()
      end,
      opts = { desc = "Papis: show popup of the entry under cursor" },
    },
  },
}

local M = {}

---Sets up either the commands of all enabled modules or of a given module
---@param module? string #Name of the module to be set up
function M.setup(module)
  if not module then
    for module_name, module_commands in pairs(commands) do
      if config["enable_modules"][module_name] then
        for _, command in pairs(module_commands) do
          api.nvim_buf_create_user_command(0, command["name"], command["command"], command["opts"])
        end
      end
    end
  else
    for _, command in pairs(commands[module]) do
      api.nvim_buf_create_user_command(0, command["name"], command["command"], command["opts"])
    end
  end
end

return M
