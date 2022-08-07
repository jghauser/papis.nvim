--
-- PAPIS | CONFIG
--
--
-- Defines all the default configuration values.
--

---Queries papis to get info-name and dir settings. It is very slow and shouldn't be used
---if possible.
---@return table #A table { info_name = val, dir = val }
local function get_papis_py_conf()
	local keys_to_get = { "info-name", "notes-name", "dir" }
	local papis_py_conf = {}
	for _, key in ipairs(keys_to_get) do
		local handle = io.popen("papis config " .. key)
		if handle then
			papis_py_conf[string.gsub(key, "-", "_")] = string.gsub(handle:read("*a"), "\n", "")
			handle:close()
		end
		if papis_py_conf["dir"] then
			local dir = papis_py_conf["dir"]
			if string.sub(dir, 1, 1) == "~" then
				dir = os.getenv("HOME") .. string.sub(dir, 2, #dir)
			end
			papis_py_conf["dir"] = dir
		end
	end
	return papis_py_conf
end

-- default configuration values
local default_config = {
	enable_modules = {
		["cursor-actions"] = true,
		["search"] = true,
		["completion"] = true,
		["formatter"] = true,
		["colors"] = true,
		["base"] = true,
		["debug"] = false,
	}, -- can be set to nil or false or left out
	cite_formats = {
		tex = "\\cite{%s}",
		md = "@%s",
		markdown = "@%s",
		rmd = "@%s",
		pandoc = "@%s",
		plain = "%s",
		org = "[cite:@%s]",
	},
	cite_formats_fallback = "plain",
	enable_keymaps = false,
	enable_commands = true,
	enable_fs_watcher = true,
	data_tbl_schema = { -- only "text" and "luatable" are allowed
		id = { "integer", pk = true },
		ref = { "text", required = true, unique = true },
		author = "text",
		editor = "text",
		year = "text",
		title = "text",
		type = "text",
		abstract = "text",
		time_added = "text",
		notes = "luatable",
		journal = "text",
		author_list = "luatable",
		tags = "luatable",
		files = "luatable",
	},
	db_path = vim.fn.stdpath("data") .. "/papis_db/papis-nvim.sqlite3",
	papis_python = get_papis_py_conf,
	create_new_note_fn = function(ref, notes_name)
		vim.fn.system(
			string.format("papis update --set notes %s ref:%s", vim.fn.shellescape(notes_name), vim.fn.shellescape(ref))
		)
	end,
	init_filenames = { "%info_name%", "*.md", "*.norg" }, -- if %info_name%, then needs to be at first position
	["formatter"] = {
		format_notes_fn = function(entry)
			local title_format = {
				{ "author", "%s ", "" },
				{ "year", "(%s) ", "" },
				{ "title", "%s", "" },
			}
			local title = require("papis.utils"):format_display_strings(entry, title_format)
			for k, v in ipairs(title) do
				title[k] = v[1]
			end
			local lines = {
				"@document.meta",
				"title: " .. table.concat(title),
				"description: ",
				"categories: [",
				"  notes",
				"  academia",
				"  readings",
				"]",
				"created: " .. os.date("%Y-%m-%d"),
				"version: " .. require("neorg.config").version,
				"@end",
				"",
			}
			vim.api.nvim_buf_set_lines(0, 0, #lines, false, lines)
			vim.cmd("normal G")
		end,
	},
	["cursor-actions"] = {
		popup_format = {
			{ "author", "%s", "PapisPopupAuthor" },
			{ "year", "%s", "PapisPopupYear" },
			{ "title", "%s", "PapisPopupTitle" },
		},
	},
	["search"] = {
		wrap = true,
		search_keys = { "author", "editor", "year", "title", "tags" }, -- also possible: "type"
		preview_format = {
			{ "author", "%s", "papispreviewauthor" },
			{ "year", "%s", "PapisPreviewYear" },
			{ "title", "%s", "PapisPreviewTitle" },
			{ "empty_line" },
			{ "ref", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
			{ "type", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
			{ "tags", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
			{ "files", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
			{ "notes", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
			{ "journal", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
			{ "abstract", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
		},
		results_format = {
			{ "author", "%s ", "PapisResultsAuthor" },
			{ "year", "(%s) ", "PapisResultsYear" },
			{ "title", "%s", "PapisResultsTitle" },
		},
	},
	["papis-storage"] = {
		key_name_conversions = {
			time_added = "time-added",
		},
		tag_format = nil,
	},
	log = {
		level = "off", -- off turns it off
		notify_format = "%s",
	},
}

local M = vim.deepcopy(default_config)

---Updates the default configuration with user supplied options
---@param opts table #Same format as default_config and contains user config
function M:update(opts)
	local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

	-- get papis options if not explicitly given in setup
	if type(newconf["papis_python"]) == "function" then
		newconf["papis_python"] = newconf["papis_python"]()
	end

	-- replace %info_name% with actual value
	if newconf["init_filenames"][1] == "%info_name%" then
		table.remove(newconf["init_filenames"], 1)
		table.insert(newconf["init_filenames"], newconf["papis_python"]["info_name"])
	end

	-- if debug mode is on, log level should be at least debug
	if newconf["enable_modules"]["debug"] == true then
		if newconf["log"]["level"] ~= "trace" then
			newconf["log"]["level"] = "debug"
		end
	end

	for k, v in pairs(newconf) do
		self[k] = v
	end
end

return M
