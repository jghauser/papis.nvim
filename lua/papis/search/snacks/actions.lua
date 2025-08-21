--
-- PAPIS | SNACKS | ACTIONS
--

---@module 'snacks'

local config = require("papis.config")
local utils = require("papis.utils")

local M = {}

---Inserts ref(s) into the current buffer
---@param picker snacks.Picker The picker instance
---@param item snacks.picker.Item The item that was selected
---@type snacks.picker.Action.fn
function M.ref_insert(picker, item)
  ---@type snacks.picker.Item[]
  local selected = picker.list.selected
  picker:close()

  local cite_format = config:get_cite_format()
  local start_str = cite_format.start_str or ""
  local end_str = cite_format.end_str or ""
  local ref_prefix = cite_format.ref_prefix or ""
  local separator_str = cite_format.separator_str
  local string_to_insert = ""

  -- Get the current line and cursor position
  local current_line = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)[2] + 1

  -- Check if the cursor is enclosed by start_str and end_str
  local enclosed = current_line:sub(1, cursor_pos - 1):find(start_str, 1, true)
      and current_line:sub(cursor_pos):find(end_str, 1, true)

  if not enclosed then
    string_to_insert = start_str
  end

  if vim.tbl_isempty(selected) then
    local ref = ref_prefix .. item.entry.ref
    string_to_insert = string_to_insert .. ref
  else
    local refs = {}
    for _, it in pairs(selected) do
      refs[#refs + 1] = ref_prefix .. it.entry.ref
    end
    string_to_insert = string_to_insert .. table.concat(refs, separator_str)
  end

  if not enclosed then
    string_to_insert = string_to_insert .. end_str
  end

  vim.api.nvim_put({ string_to_insert }, "", false, true)
end

---Inserts full reference(s) into the buffer
---@param picker snacks.Picker The picker instance
---@param item snacks.picker.Item The item that was selected
---@type snacks.picker.Action.fn
function M.ref_insert_formatted(picker, item)
  ---@type snacks.picker.Item[]
  local selected = picker.list.selected
  picker:close()

  local string_to_insert = ""
  if vim.tbl_isempty(selected) then
    local full_reference = config["formatter"].format_references(item.entry)
    string_to_insert = full_reference[1]
  else
    for _, it in pairs(selected) do
      local full_reference = config["formatter"].format_references(it.entry)
      string_to_insert = string_to_insert .. full_reference[1] .. " "
    end
  end

  vim.api.nvim_put({ string_to_insert }, "", false, true)
end

---Opens attached file(s)
---@param picker snacks.Picker The picker instance
---@param item snacks.picker.Item The item that was selected
---@type snacks.picker.Action.fn
function M.open_file(picker, item)
  local selected = picker.list.selected
  picker:close()

  if vim.tbl_isempty(selected) then
    utils:do_open_attached_files(item.entry.papis_id)
  else
    for _, it in pairs(selected) do
      utils:do_open_attached_files(it.entry.papis_id)
    end
  end
end

---Opens attached note(s)
---@param picker snacks.Picker The picker instance
---@param item snacks.picker.Item The item that was selected
---@type snacks.picker.Action.fn
function M.open_note(picker, item)
  local selected = picker.list.selected
  picker:close()

  if vim.tbl_isempty(selected) then
    utils:do_open_text_file(item.entry.papis_id, "note")
  else
    for _, it in pairs(selected) do
      utils:do_open_text_file(it.entry.papis_id, "note")
    end
  end
end

---Opens metadata info file(s)
---@param picker snacks.Picker The picker instance
---@param item snacks.picker.Item The item that was selected
---@type snacks.picker.Action.fn
function M.open_info(picker, item)
  local selected = picker.list.selected
  picker:close()

  if vim.tbl_isempty(selected) then
    utils:do_open_text_file(item.entry.papis_id, "info")
  else
    for _, it in pairs(selected) do
      utils:do_open_text_file(it.entry.papis_id, "info")
    end
  end
end

return M
