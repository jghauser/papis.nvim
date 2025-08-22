--
-- PAPIS | ASK
--
--
-- Integrates with the papis ask plugin
--

local log = require("papis.log")
local config = require("papis.config")
local commands = require("papis.commands")
local keymaps = require("papis.keymaps")

local ask_config = config.ask or config["ask"]
local provider = ask_config.provider

---@class PapisKeymaps
local module_keymaps = {
  open_ask_normal = {
    mode = "n",
    lhs = "<leader>pa",
    rhs = function()
      vim.cmd("Papis ask")
    end,
    opts = { desc = "Papis: open ask picker" },
  },
  open_ask_insert = {
    mode = "i",
    lhs = "<c-o>a",
    rhs = function()
      vim.cmd("Papis ask")
    end,
    opts = { desc = "Papis: open ask picker" },
  },
}

---Setup snacks ask provider
---@return boolean #Whether setup succeeded
local function setup_snacks()
  local has_snacks, _ = pcall(require, "snacks")
  if not has_snacks then
    return false
  end

  commands:add_commands({
    ask = {
      impl = function(_, _)
        require("papis.ask.snacks").picker()
      end,
    },
  })
  keymaps:add_keymaps(module_keymaps)
  return true
end

---Setup telescope ask provider
---@return boolean #Whether setup succeeded
local function setup_telescope()
  local has_telescope, _ = pcall(require, "telescope")
  if not has_telescope then
    return false
  end

  commands:add_commands({
    ask = {
      impl = function(_, _)
        require("papis.ask.telescope").exports.papis_ask()
      end,
    },
  })
  keymaps:add_keymaps(module_keymaps)
  return true
end


local M = {}

---Sets up the papis.nvim ask module
function M.setup()
  log.debug("Ask: setting up module with provider: " .. provider)

  if provider == "auto" then
    -- Try snacks first, then fall back to telescope
    if not setup_snacks() and not setup_telescope() then
      error("Neither snacks.nvim nor telescope.nvim was found. Please install one of them or change the ask provider.")
    end
  elseif provider == "snacks" then
    if not setup_snacks() then
      error("The plugin snacks.nvim wasn't found but it's configured as the ask provider.")
    end
  elseif provider == "telescope" then
    if not setup_telescope() then
      error("The plugin telescope.nvim wasn't found but it's configured as the ask provider.")
    end
  else
    error("Invalid ask provider: " .. provider .. ". Valid options are 'auto', 'snacks', or 'telescope'.")
  end
end

return M
