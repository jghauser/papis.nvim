--
-- PAPIS | TELESCOPE | ACTIONS
--
--
-- With some code from: https://github.com/nvim-telescope/telescope-bibtex.nvim

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local config = require("papis.config")
local db = require("papis.sqlite-wrapper")

local utils = require("papis.utils")

local get_multi = function(prompt_bufnr)
  local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
  local multi = picker:get_multi_selection()
  return multi
end

local M = {}

---This function inserts a formatted ref string at the cursor
---@param prompt_bufnr number @The buffer number of the prompt
---@param format_string string @The string to be inserted
M.ref_insert = function(prompt_bufnr, format_string)
  local multi = get_multi(prompt_bufnr)

  actions.close(prompt_bufnr)
  local string_to_insert = ""
  if vim.tbl_isempty(multi) then
    local ref = string.format(format_string, action_state.get_selected_entry().id.ref)
    string_to_insert = ref
  else
    for _, entry in pairs(multi) do
      local ref = string.format(format_string, entry.id.ref)
      string_to_insert = string_to_insert .. ref .. " "
    end
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
    local full_reference = config["formatter"].format_references_fn(full_entry)
    string_to_insert = full_reference
  else
    for _, entry in pairs(multi) do
      local papis_id = entry.id.papis_id
      local full_entry = db.data:get({ papis_id = papis_id })[1]
      local full_reference = config["formatter"].format_references_fn(full_entry)
      string_to_insert = string_to_insert .. full_reference .. " "
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
      -- TODO: this only opens one note if a note needs to be created
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
