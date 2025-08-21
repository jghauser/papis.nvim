--
-- PAPIS | ASK | SNACKS | ACTIONS
--
--
-- Actions for the ask snacks picker

local log = require("papis.log")
local picker_common = require("papis.ask.picker_common")

local M = {}

---Open the full answer in a buffer
---@type snacks.picker.Action.fn
---@param picker snacks.Picker The picker instance
---@param item snacks.picker.Item The selected item
function M.open_answer(picker, item)
  ---@type snacks.picker.Item[]
  local selected = picker.list.selected
  picker:close()

  if item and item.entry.placeholder then
    return
  end

  local input = picker.finder.filter.pattern
  local slash, question = input:match("^/(%w+)%s+(.*)")

  if slash and question and question ~= "" then
    picker_common.run_slash_command(slash, question)
  elseif not vim.tbl_isempty(selected) then
    for _, it in pairs(selected) do
      picker_common.open_answer(it.entry)
    end
  elseif item then
    picker_common.open_answer(item.entry)
  end
end

---Delete an ask entry
---@type snacks.picker.Action.fn
---@param picker snacks.Picker The picker instance
---@param item snacks.picker.Item The selected item
function M.delete_answer(picker, item)
  if item and item.entry.placeholder then
    return
  end

  ---@type snacks.picker.Item[]
  local selected = picker.list.selected

  if not vim.tbl_isempty(selected) then
    for _, it in pairs(selected) do
      picker_common.delete_entry(it.entry)
    end
    -- Refresh the picker
    picker:find()
  elseif item then
    picker_common.delete_entry(item.entry)
    -- Refresh the picker
    picker:find()
  end
end

return M
