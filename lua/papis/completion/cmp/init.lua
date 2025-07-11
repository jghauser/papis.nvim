--
-- PAPIS | COMPLETION | CMP
--
--
-- The cmp source.
--

local log = require("papis.log")
local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end
local common = require("papis.completion.common")
if not common then
  return nil
end

--- @module 'cmp-nvim completion source'
--- @class papis.completion.cmp
local M = {}

---Creates a new cmp source
---@return table
function M.new()
  return setmetatable({}, { __index = M })
end

---Gets trigger characters
---@return table
M.get_trigger_characters = common.get_trigger_characters

---Ensures that this source is only available in info_name files, and only for the "tags" key
---@return boolean #True if info_name file, false otherwise
M.is_available = common.is_available

---Completes the current request
---@param _ table #The request
---@param callback function
function M:complete(_, callback)
  -- Insert a space after the dash and move cursor
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { " " })
  vim.api.nvim_win_set_cursor(0, { row, col + 1 })

  log.debug("Running cmp `complete()` function.")
  self.items = db.completion:get()[1].tag_strings
  callback(self.items)
end

return M
