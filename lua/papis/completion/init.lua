--
-- PAPIS | COMPLETION
--
--
-- Initialises the papis.nvim completion module.
--

local log = require("papis.log")
local provider = require("papis.config").completion.provider

local M = {}

---Setup blink completion provider
---@return boolean success Whether setup succeeded
local function setup_blink()
  local has_blink, blink = pcall(require, "blink.cmp")
  if not has_blink then
    return false
  end

  require("papis.completion.data").init()
  blink.add_source_provider("papis", {
    name = "papis",
    module = "papis.completion.blink",
    async = true,
    opts = {},
    enabled = true
  })
  return true
end

---Setup cmp completion provider
---@return boolean success Whether setup succeeded
local function setup_cmp()
  local has_cmp, cmp = pcall(require, "cmp")
  if not has_cmp then
    return false
  end

  require("papis.completion.data").init()
  cmp.register_source("papis", require("papis.completion.cmp").new())
  return true
end

---Sets up the papis.nvim completion source
function M.setup()
  log.debug("Completion: setting up module with provider: " .. provider)

  if provider == "auto" then
    -- Try blink first, then fall back to cmp
    if not setup_blink() and not setup_cmp() then
      error("Neither blink.nvim nor nvim-cmp was found. Please install one of \
      them or change the completion provider.")
    end
  elseif provider == "blink" then
    if not setup_blink() then
      error("The plugin blink.nvim wasn't found but it's configured as the \
      completion provider.")
    end
  elseif provider == "cmp" then
    if not setup_cmp() then
      error("The plugin nvim-cmp wasn't found but it's configured as the \
      completion provider.")
    end
  else
    error("Invalid completion provider: " .. provider .. ". Valid options are \
    'auto', 'cmp', or 'blink'.")
  end
end

return M
