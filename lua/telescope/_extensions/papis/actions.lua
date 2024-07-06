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

local M = {}

---This function inserts a formatted reference string at the cursor
---@param prompt_bufnr number @The buffer number of the prompt
---@param format_string string @The string to be inserted
M.ref_insert = function(prompt_bufnr, format_string)
  local entry = string.format(format_string, action_state.get_selected_entry().id.ref)
  actions.close(prompt_bufnr)
  vim.api.nvim_put({ entry }, "", false, true)
end

---This function inserts a formatted reference string at the cursor
---@param prompt_bufnr number @The buffer number of the prompt
M.ref_insert_formatted = function(prompt_bufnr)
  actions.close(prompt_bufnr)
  local papis_id = action_state.get_selected_entry().id.papis_id
  local entry = db.data:get({ papis_id = papis_id })[1]
  local reference = config["formatter"].format_references_fn(entry)

  vim.api.nvim_put({ reference }, "", false, true)
end

---This function opens the files attached to the current entry
---@param prompt_bufnr number @The buffer number of the prompt
M.open_file = function(prompt_bufnr)
  local papis_id = action_state.get_selected_entry().id.papis_id
  actions.close(prompt_bufnr)
  utils:do_open_attached_files(papis_id)
end

---This function opens the note attached to the current entry
---@param prompt_bufnr number @The buffer number of the prompt
M.open_note = function(prompt_bufnr)
  local papis_id = action_state.get_selected_entry().id.papis_id
  actions.close(prompt_bufnr)
  utils:do_open_text_file(papis_id, "note")
end

---This function opens the info_file containing this entry's information
---@param prompt_bufnr number @The buffer number of the prompt
M.open_info = function(prompt_bufnr)
  local papis_id = action_state.get_selected_entry().id.papis_id
  actions.close(prompt_bufnr)
  utils:do_open_text_file(papis_id, "info")
end

return M
