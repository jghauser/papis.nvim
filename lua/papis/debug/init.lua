--
-- PAPIS | DEBUG
--
--
-- Debugging module.
--

local log = require("papis.log")
local commands = require("papis.commands")

---@class PapisSubcommand
local module_subcommands = {
  debug = {
    impl = function(args, _)
      if args[1] == "start-watchers" then
        require("papis.fs-watcher").start()
      elseif args[1] == "stop-watchers" then
        require("papis.fs-watcher").stop()
      elseif args[1] == "info" then
        require("papis.log").get_path()
      end
    end,
    complete = function(subcmd_arg_lead)
      local debug_args = {
        "start-watchers",
        "stop-watchers",
        "info",
      }
      return vim.iter(debug_args)
          :filter(function(install_arg)
            return install_arg:find(subcmd_arg_lead) ~= nil
          end)
          :totable()
    end,
  }
}

local M = {}

---Sets up the debug module
function M.setup()
  log.debug("Setting up debug module")
  commands:add_commands(module_subcommands)
end

return M
