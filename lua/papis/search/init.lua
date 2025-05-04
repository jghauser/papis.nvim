--
-- PAPIS | SEARCH
--
-- Initialises the papis.nvim search module.
--

local log = require("papis.log")
local config = require("papis.config")
local commands = require("papis.commands")
local keymaps = require("papis.keymaps")
local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end

---@class PapisSubcommand
local module_subcommands = {
  search = {
    impl = function(_, _)
      if config["search"].provider == "telescope" then
        require("papis.search.telescope").exports.papis()
      elseif config["search"].provider == "snacks" then
        require("papis.search.snacks").picker()
      end
    end,
  },
}

---@class PapisKeymaps
local module_keymaps = {
  open_search_normal = {
    mode = "n",
    lhs = "<leader>pp",
    rhs = function()
      vim.cmd("Papis search")
    end,
    opts = { desc = "Papis: search library" },
  },
  open_search_insert = {
    mode = "i",
    lhs = "<c-o>p",
    rhs = function()
      vim.cmd("Papis search")
    end,
    opts = { desc = "Papis: search library" },
  },
}

local M = {}

---Sets up the papis.nvim picker
function M.setup()
  log.debug("Search: setting up module")
  require("papis.search.data").init()
  if config["search"].provider == "telescope" then
    local has_telescope, telescope = pcall(require, "telescope")
    if not has_telescope then
      error("The plugin telescope.nvim wasn't found but the search module is enabled and requires it.")
    end

    commands:add_commands(module_subcommands)
    keymaps:add_keymaps(module_keymaps)
  elseif config["search"].provider == "snacks" then
    local has_snacks, _ = pcall(require, "snacks")
    if not has_snacks then
      error("The plugin snacks.nvim wasn't found but the search module is enabled and requires it.")
    end

    commands:add_commands(module_subcommands)
    keymaps:add_keymaps(module_keymaps)
  else
    error("The search module is enabled but no valid provider was specified.")
  end
end

return M
