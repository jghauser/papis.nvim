--
-- PAPIS | FORMATTER
--
--
-- This modules formats new notes created by papis.nvim using a template function.
--

local log = require("papis.log")
local config = require("papis.config")

local api = vim.api

---@class PapisFormatter
local M = {}

---Formats a new notes file
---@param entry PapisEntry The entry to which the notes file belongs
function M.format_entire_file(entry)
  log.debug("Formatting new notes file")
  local lines = config["formatter"].format_notes(entry)
  local notes_path = entry.notes[1]
  local buf = api.nvim_create_buf(false, false)
  api.nvim_buf_set_name(buf, notes_path)
  api.nvim_buf_set_lines(buf, 0, #lines, false, lines)
  api.nvim_buf_call(buf, function()
    vim.cmd('write')
  end)
  api.nvim_buf_delete(buf, {})
end

return M
