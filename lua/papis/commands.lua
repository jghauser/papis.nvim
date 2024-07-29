--
-- PAPIS | COMMANDS
--
--
-- Sets up default commands.
--
-- Adapted from https://github.com/nvim-neorocks/nvim-best-practices

---@class PapisSubcommand
---@field impl fun(args:string[], opts: table) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] (optional) Command completions callback, taking the lead of the subcommand's arguments
---@type table<string, PapisSubcommand>
local subcommand_tbl = {
  reload = {
    impl = function(args, _)
      -- Implementation (args is a list of strings)
      if args[1] == "config" then
        require("papis.sqlite-wrapper").config:update()
      elseif args[1] == "data" then
        require("papis.data"):reset_db()
      end
    end,
    complete = function(subcmd_arg_lead)
      -- Simplified example
      local reload_args = {
        "config",
        "data",
      }
      return vim.iter(reload_args)
          :filter(function(install_arg)
            -- If the user has typed `:Papis reload co`,
            -- this will match 'config'
            return install_arg:find(subcmd_arg_lead) ~= nil
          end)
          :totable()
    end,
  },
}

---Main Papis command
---@param opts table
local function papis_cmd(opts)
  local fargs = opts.fargs
  local subcommand_key = fargs[1]
  -- Get the subcommand's arguments, if any
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local subcommand = subcommand_tbl[subcommand_key]
  if not subcommand then
    vim.notify("Papis: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)
    return
  end
  -- Invoke the subcommand
  subcommand.impl(args, opts)
end

---Creates the main Papis command
local function create_command()
  vim.api.nvim_create_user_command("Papis", papis_cmd, {
    nargs = "+",
    desc = "Papis main command (with subcommands)",
    complete = function(arg_lead, cmdline, _)
      -- Get the subcommand.
      local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*Papis[!]*%s(%S+)%s(.*)$")
      if subcmd_key
          and subcmd_arg_lead
          and subcommand_tbl[subcmd_key]
          and subcommand_tbl[subcmd_key].complete
      then
        -- The subcommand has completions. Return them.
        return subcommand_tbl[subcmd_key].complete(subcmd_arg_lead)
      end
      -- Check if cmdline is a subcommand
      if cmdline:match("^['<,'>]*Papis[!]*%s+%w*$") then
        -- Filter subcommands that match
        local subcommand_keys = vim.tbl_keys(subcommand_tbl)
        return vim.iter(subcommand_keys)
            :filter(function(key)
              return key:find(arg_lead) ~= nil
            end)
            :totable()
      end
    end,
  })
end

local M = {}

---Sets up main "Papis" command
function M.setup()
  create_command()
end

--- Recursively merges the provided table with the subcommand_tbl table.
---@param module_subcommand table #A table with a module's commands
function M:add_commands(module_subcommand)
  subcommand_tbl = vim.tbl_extend("force", subcommand_tbl, module_subcommand)
end

return M
