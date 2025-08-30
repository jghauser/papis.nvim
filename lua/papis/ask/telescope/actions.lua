-- PAPIS | ASK | TELESCOPE | ACTIONS
-- Minimal actions file for ask picker

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")

local picker_common = require("papis.ask.picker_common")
local ask_telescope = require("papis.ask.telescope")

---Gets all items selected in the picker
---@param prompt_bufnr number The buffer number of the prompt
---@return TelescopeItem[] selected A list of all selected items
local get_selected = function(prompt_bufnr)
  local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
  return picker:get_multi_selection()
end

local M = {}

---Open the full answer in a buffer or run slash command
---@param prompt_bufnr number The buffer number of the prompt
function M.open_answer(prompt_bufnr)
  local selected = get_selected(prompt_bufnr)
  actions.close(prompt_bufnr)

  local item = action_state.get_selected_entry()
  if item and item.entry.placeholder then
    return
  end

  local input = action_state.get_current_line()
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
---@param prompt_bufnr number The buffer number of the prompt
function M.delete_answer(prompt_bufnr)
  local selected = get_selected(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local item = action_state.get_selected_entry()

  if item and item.entry.placeholder then
    return
  end

  local function refresh_picker()
    local new_items = ask_telescope.get_items()

    local entry_maker = picker.finder.entry_maker
    local new_finder = finders.new_table {
      results = new_items,
      entry_maker = entry_maker,
    }

    -- clear multi selection to avoid stale handles
    picker._multi = {}

    picker:refresh(new_finder, { reset_prompt = true })
  end

  if not vim.tbl_isempty(selected) then
    for _, it in pairs(selected) do
      picker_common.delete_entry(it.entry)
    end
    refresh_picker()
  elseif item then
    picker_common.delete_entry(item.entry)
    refresh_picker()
  end
end

return M
