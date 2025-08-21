--
-- PAPIS | TELESCOPE | ACTIONS
--
--
-- With some code from: https://github.com/nvim-telescope/telescope-bibtex.nvim

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local config = require("papis.config")
local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")

local utils = require("papis.utils")

local get_multi = function(prompt_bufnr)
  local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
  local multi = picker:get_multi_selection()
  return multi
end

local M = {}

---This function inserts a formatted ref string at the cursor
---@param prompt_bufnr number @The buffer number of the prompt
M.ref_insert = function(prompt_bufnr)
  local multi = get_multi(prompt_bufnr)
  actions.close(prompt_bufnr)
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

  if vim.tbl_isempty(multi) then
    local ref = ref_prefix .. action_state.get_selected_entry().id.ref
    string_to_insert = string_to_insert .. ref
  else
    local refs = {}
    for _, entry in pairs(multi) do
      refs[#refs + 1] = ref_prefix .. entry.id.ref
    end
    string_to_insert = string_to_insert .. table.concat(refs, separator_str)
  end

  if not enclosed then
    string_to_insert = string_to_insert .. end_str
  end

  vim.api.nvim_put({ string_to_insert }, "", false, true)
end

---This function inserts a formatted full reference at the cursor
---@param prompt_bufnr number @The buffer number of the prompt
M.ref_insert_formatted = function(prompt_bufnr)
  local multi = get_multi(prompt_bufnr)

  actions.close(prompt_bufnr)
  local string_to_insert = ""
  if vim.tbl_isempty(multi) then
    local papis_id = action_state.get_selected_entry().id.papis_id
    local full_entry = db.data:get({ papis_id = papis_id })[1]
    local full_reference = config["formatter"].format_references(full_entry)
    string_to_insert = full_reference[1]
  else
    for _, entry in pairs(multi) do
      local papis_id = entry.id.papis_id
      local full_entry = db.data:get({ papis_id = papis_id })[1]
      local full_reference = config["formatter"].format_references(full_entry)
      -- TODO: this should be able to use arbitary length `full_reference`s
      string_to_insert = string_to_insert .. full_reference[1] .. " "
    end
  end

  vim.api.nvim_put({ string_to_insert }, "", false, true)
end

---This function opens the files attached to the current entry
---@param prompt_bufnr number @The buffer number of the prompt
M.open_file = function(prompt_bufnr)
  local multi = get_multi(prompt_bufnr)

  actions.close(prompt_bufnr)
  if vim.tbl_isempty(multi) then
    local papis_id = action_state.get_selected_entry().id.papis_id
    utils:do_open_attached_files(papis_id)
  else
    for _, entry in pairs(multi) do
      local papis_id = entry.id.papis_id
      utils:do_open_attached_files(papis_id)
    end
  end
end

---This function opens the note attached to the current entry
---@param prompt_bufnr number @The buffer number of the prompt
M.open_note = function(prompt_bufnr)
  local multi = get_multi(prompt_bufnr)

  actions.close(prompt_bufnr)
  if vim.tbl_isempty(multi) then
    local papis_id = action_state.get_selected_entry().id.papis_id
    utils:do_open_text_file(papis_id, "note")
  else
    for _, entry in pairs(multi) do
      local papis_id = entry.id.papis_id
      utils:do_open_text_file(papis_id, "note")
    end
  end
end

---This function opens the info_file containing this entry's information
---@param prompt_bufnr number @The buffer number of the prompt
M.open_info = function(prompt_bufnr)
  local multi = get_multi(prompt_bufnr)

  actions.close(prompt_bufnr)
  if vim.tbl_isempty(multi) then
    local papis_id = action_state.get_selected_entry().id.papis_id
    utils:do_open_text_file(papis_id, "info")
  else
    for _, entry in pairs(multi) do
      local papis_id = entry.id.papis_id
      utils:do_open_text_file(papis_id, "info")
    end
  end
end

return M
