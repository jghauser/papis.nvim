--
-- PAPIS | COMPLETION | BLINK
--
--
-- The blink source.
--

local log = require("papis.log")
local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")
local common = assert(require("papis.completion.common"), "Failed to load papis.completion.common")

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
function M.get_trigger_characters()
  return { "-" }
end

---Ensures that this source is only available in info_name files, and only for the "tags" key
---@return boolean is_available True if info_name file, false otherwise
M.enabled = common.is_available

---Completes the current request
---@param _ table The ctx table
---@param callback function
function M:get_completions(_, callback)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  -- check if we're just after a `-` that is preceded by nothing but whitespace
  local before = (vim.api.nvim_buf_get_text(0, row - 1, 0, row - 1, col, {})[1]) or ""
  if not before:match("^%s*-$") then
    return callback({
      items = {},
      is_incomplete_backward = false,
      is_incomplete_forward = false,
    })
  end

  -- jump forward a space
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { " " })
  vim.api.nvim_win_set_cursor(0, { row, col + 1 })
  col = col + 1

  local tag_strings = db.completion:get()[1].tag_strings
  local items = {}
  for _, tag in ipairs(tag_strings) do
    table.insert(items, { label = tag.label })
  end

  callback({
    items = items,
    is_incomplete_backward = false,
    is_incomplete_forward = false,
  })
end

return M
