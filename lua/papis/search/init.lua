--
-- PAPIS | SEARCH
--
-- Initialises the papis.nvim search module.
--

local log = require("papis.log")
local config = require("papis.config")

local provider = config.search.provider
local commands = require("papis.commands")
local keymaps = require("papis.keymaps")
local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end

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

---Setup snacks search provider
---@return boolean #Whether setup succeeded
local function setup_snacks()
  local has_snacks, _ = pcall(require, "snacks")
  if not has_snacks then
    return false
  end

  require("papis.search.data").init()
  commands:add_commands({
    search = {
      impl = function(_, _)
        require("papis.search.snacks").picker()
      end,
    },
  })
  keymaps:add_keymaps(module_keymaps)
  return true
end

---Setup telescope search provider
---@return boolean #Whether setup succeeded
local function setup_telescope()
  local has_telescope, _ = pcall(require, "telescope")
  if not has_telescope then
    return false
  end

  require("papis.search.data").init()
  commands:add_commands({
    search = {
      impl = function(_, _)
        require("papis.search.telescope").exports.papis()
      end,
    },
  })
  keymaps:add_keymaps(module_keymaps)
  return true
end

local M = {}

---Sets up the papis.nvim picker
function M.setup()
  log.debug("Search: setting up module with provider: " .. provider)

  if provider == "auto" then
    -- Try snacks first, then fall back to telescope
    if not setup_snacks() and not setup_telescope() then
      error("Neither snacks.nvim nor telescope.nvim was found. Please install one of \
      them or change the search provider.")
    end
  elseif provider == "snacks" then
    if not setup_snacks() then
      error("The plugin snacks.nvim wasn't found but it's configured as the \
      search provider.")
    end
  elseif provider == "telescope" then
    if not setup_telescope() then
      error("The plugin telescope.nvim wasn't found but it's configured as the \
      search provider.")
    end
  else
    error("Invalid search provider: " .. provider .. ". Valid options are \
    'auto', 'snacks', or 'telescope'.")
  end
end

return M
