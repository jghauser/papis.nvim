--
-- PAPIS | COMPLETION | BLINK
--
--
-- The blink source.
--

---@module 'blink-cmp'

local log = require("papis.log")
local common = assert(require("papis.completion.common"), "Failed to load papis.completion.common")

---@class PapisCompletionBlink : blink.cmp.Source
local M = {}

---Creates a new cmp source
---@return blink.cmp.Source
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
---@param _ table The context table
---@param callback function
function M:get_completions(_, callback)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  -- check if we're just after a `-` that is preceded by nothing but whitespace
  -- if so advance by one whitespace
  local before = (vim.api.nvim_buf_get_text(0, row - 1, 0, row - 1, col, {})[1]) or ""
  if before:match("^%s*-$") then
    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { " " })
    vim.api.nvim_win_set_cursor(0, { row, col + 1 })
  end

  log.debug("Running blink completion")
  callback({
    items = common.get_completion_items(),
    is_incomplete_backward = false,
    is_incomplete_forward = false,
  })
end

return M
