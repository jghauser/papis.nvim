--
-- PAPIS | KEYMAPS
--
--
-- Sets up default keymaps.
--

local config = require("papis.config")

local M = {}

---@class PapisKeymaps
---@type table<string, table>
local keymaps = {}

---Sets up the keymaps for all enabled modules
function M:setup()
  self:add_keymaps(keymaps)
end

--- Recursively merges the provided table with the keymaps table.
---@param module_keymaps table #A table with a module's keymaps
function M:add_keymaps(module_keymaps)
  if config["enable_keymaps"] then
    for _, keymap in pairs(module_keymaps) do
      local opts = vim.deepcopy(keymap["opts"])
      opts["silent"] = true
      opts["buffer"] = true
      vim.keymap.set(keymap["mode"], keymap["lhs"], keymap["rhs"], opts)
    end
  end
end

return M
