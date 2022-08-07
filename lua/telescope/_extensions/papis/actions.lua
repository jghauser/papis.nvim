--
-- PAPIS | TELESCOPE | ACTIONS
--
--
-- With some code from: https://github.com/nvim-telescope/telescope-bibtex.nvim

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local utils = require("papis.utils")

M = {}

---This function inserts a formatted reference string at the cursor
---@param format_string string @The string to be inserted
---@return function
M.ref_insert = function(format_string)
	return function(prompt_bufnr)
		local entry = string.format(format_string, action_state.get_selected_entry().id.ref)
		actions.close(prompt_bufnr)
		vim.api.nvim_put({ entry }, "", true, true)
		vim.api.nvim_feedkeys("a", "n", true)
	end
end

---This function opens the files attached to the current entry
---@return function
M.open_file = function()
	return function(prompt_bufnr)
		local ref = action_state.get_selected_entry().id.ref
		actions.close(prompt_bufnr)
		utils:do_open_attached_files(ref)
	end
end

---This function opens the note attached to the current entry
---@return function
M.open_note = function()
	return function(prompt_bufnr)
		local ref = action_state.get_selected_entry().id.ref
		actions.close(prompt_bufnr)
		utils:do_open_text_file(ref, "note")
	end
end

---This function opens the info_file containing this entry's information
---@return function
M.open_info = function()
	return function(prompt_bufnr)
		local ref = action_state.get_selected_entry().id.ref
		actions.close(prompt_bufnr)
		utils:do_open_text_file(ref, "info")
	end
end

return M
