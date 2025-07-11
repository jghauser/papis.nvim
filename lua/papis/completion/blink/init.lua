--
-- PAPIS | COMPLETION | BLINK
--
--
-- The blink source.
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

--- @module 'blink.cmp completion source'
--- @class papis.completion.blink
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
M.enabled = common.is_available

---Completes the current request
---@param _ table #The ctx table
---@param callback function
function M:get_completions(_, callback)
  -- Insert a space after the dash and move cursor
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { " " })
  vim.api.nvim_win_set_cursor(0, { row, col + 1 })

  log.debug("Getting completions")
  local tag_strings = db.completion:get()[1].tag_strings
  --- @type lsp.CompletionItem[]
  local items = {}
  for _, tag in ipairs(tag_strings) do
    --- @type lsp.CompletionItem
    local item = {
      label = tag.label,
    }
    table.insert(items, item)
  end
  callback({
    items = items,
    is_incomplete_backward = false,
    is_incomplete_forward = false,
  })
end

return M
