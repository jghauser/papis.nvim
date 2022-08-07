--
-- PAPIS | CURSOR-ACTIONS
--
--
-- Various functionalities when the cursor is over a citation reference.
--

local NuiPopup = require("nui.popup")
local nuiAutocmd = require("nui.utils.autocmd")
local nuiEvent = require("nui.utils.autocmd").event

local opt = vim.opt
local fn = vim.fn

local log = require("papis.logger")
local config = require("papis.config")
local popup_format = config["cursor-actions"]["popup_format"]
local utils = require("papis.utils")
local db = require("papis.sqlite-wrapper")
if not db then
	return nil
end
local hover_required_db_keys = utils:get_required_db_keys({ popup_format })

---Tries to identify the ref under cursor
---@return string|nil #Nil if nothing is found, otherwise is the identified ref
local function get_ref_under_cursor()
	local ref
	local save_iskeyword = opt.iskeyword:get()
	opt.iskeyword = { ",", ".", "!", "?", ":", ";", "'" }
	local word_under_cursor = fn.expand("<cWORD>") .. "\n"
	opt.iskeyword = save_iskeyword
	local filetype = vim.bo.filetype
	log:debug("The filetype is: " .. filetype)
	local cite_format = utils.get_cite_format(filetype)
	log:debug("The cite_format is: " .. cite_format)
	local _, prefix_end = string.find(cite_format, "%%s")
	prefix_end = prefix_end - 2
	local cite_format_prefix = string.sub(cite_format, 1, prefix_end)
	local _, ref_start = string.find(word_under_cursor, cite_format_prefix)
	if ref_start then
		ref_start = ref_start + 1
		local ref_end = string.find(word_under_cursor, "[%s},%];\n]", ref_start)
		ref_end = ref_end - 1
		ref = string.sub(word_under_cursor, ref_start, ref_end)
	end

	return ref
end

---Runs function if there is a valid ref under cursor which exists in the database
---@param fun function #The function to be run with the ref
---@param self? table #Self argument to be passed to fun
---@param type? string #Type argument to be passed to fun
local function if_ref_valid_run_fun(fun, self, type)
	local ref = get_ref_under_cursor()
	if ref then
		local entry = db.data:get({ ref = ref }, { "id" })
		if not vim.tbl_isempty(entry) then
			if self then
				fun(self, ref, type)
			else
				fun(ref, type)
			end
		else
			log:info(string.format("No entry in database corresponds to '%s'", ref))
		end
	else
		log:info("No valid citation key found under cursor.")
	end
end

---Creates a popup with information regarding the entry specified by `ref`
---@param ref string #The `ref` of the entry
local function create_hover_popup(ref)
	local entry = db.data:get({ ref = ref }, hover_required_db_keys)[1]
	local clean_popup_format = utils.do_clean_format_tbl(popup_format, entry)
	local popup_lines, width = utils.make_nui_lines(clean_popup_format, entry)

	local popup = NuiPopup({
		position = 1,
		size = {
			width = width,
			height = #popup_lines,
		},
		relative = "cursor",
		border = {
			style = "single",
		},
	})

	local bufnr = vim.api.nvim_get_current_buf()
	nuiAutocmd.buf.define(bufnr, { nuiEvent.BufLeave, nuiEvent.CursorMoved, nuiEvent.BufWinLeave }, function()
		popup:unmount()
	end, { once = true })

	-- mount/open the component
	popup:mount()

	for line_nr, line in ipairs(popup_lines) do
		line:render(popup.bufnr, -1, line_nr)
	end
end

local M = {}

---Opens the file of the `ref` under cursor
function M.open_file()
	if_ref_valid_run_fun(utils.do_open_attached_files, utils)
end

---Opens the note of the `ref` under cursor
function M.open_note()
	if_ref_valid_run_fun(utils.do_open_text_file, utils, "note")
end

---Edits the entry of the `ref` under cursor
function M.edit_entry()
	if_ref_valid_run_fun(utils.do_open_text_file, utils, "info")
end

---Shows a popup with information about the entry of the `ref` under cursor
function M.show_popup()
	if_ref_valid_run_fun(create_hover_popup)
end

return M
