--
-- PAPIS | COMPLETION | SOURCE
--
--
-- The cmp source.
--

local Path = require("plenary.path")
local ts_utils = require("nvim-treesitter.ts_utils")
local query = require("vim.treesitter.query")
local cmd = vim.cmd
local api = vim.api

local config = require("papis.config")
local log = require("papis.logger")
local db = require("papis.sqlite-wrapper")
if not db then
	return nil
end
local tag_delimiter

---Gets tag_delimiter for the tag_format
---@return string|nil #The delimiter between tags given the format
local function get_tag_delimiter()
	local tag_format = db.state:get_value({ id = 1 }, { "tag_format" })
	if tag_format == "tbl" then
		tag_delimiter = "- "
	elseif tag_format == "," then
		tag_delimiter = ", "
	elseif tag_format == ";" then
		tag_delimiter = "; "
	elseif tag_format == " " then
		tag_delimiter = tag_format
	end
	return tag_delimiter
end

local M = {}

---Creates a new cmp source
---@return table
function M.new()
	return setmetatable({}, { __index = M })
end

---Gets trigger characters
---@return table
function M:get_trigger_characters()
	return { " " }
end

---Ensures that this source is only available in info_name files, and only for the "tags" key
---@return boolean #True if info_name file, false otherwise
function M:is_available()
	local is_available = false
	local current_filepath = Path:new((api.nvim_buf_get_name(0)))
	local split_path = current_filepath:_split()
	local filename = current_filepath:_split()[#split_path]

	if filename == config["papis_python"]["info_name"] then
		if not tag_delimiter then
			tag_delimiter = get_tag_delimiter()
		end
		local node_text

		log:trace("tag_delimiter: " .. tag_delimiter)
		if tag_delimiter == "- " then
			local cursor_position = api.nvim_win_get_cursor(0)
			cmd("normal ^")
			local node_at_cursor = ts_utils.get_node_at_cursor()
			api.nvim_win_set_cursor(0, cursor_position)
			if node_at_cursor then
				if node_at_cursor:type() == "block_sequence_item" then
					local key_node = ts_utils.get_previous_node(node_at_cursor:parent():parent())
					node_text = query.get_node_text(key_node, 0)
				end
			end
		elseif tag_delimiter then
			local cursor_position = api.nvim_win_get_cursor(0)
			api.nvim_win_set_cursor(0, { cursor_position[1], 1 })
			local node_at_cursor = ts_utils.get_node_at_cursor()
			api.nvim_win_set_cursor(0, cursor_position)
			if node_at_cursor then
				node_text = query.get_node_text(node_at_cursor, 0)
			end
		end

		if node_text == "tags" then
			is_available = true
			log:debug("cmp source is available")
		end
	end
	return is_available
end

---Completes the current request
---@param request table
---@param callback function
function M:complete(request, callback)
	if not tag_delimiter then
		tag_delimiter = get_tag_delimiter()
	end

	local prefix = string.sub(request.context.cursor_before_line, 1, request.offset)
	log:debug("Request prefix: " .. prefix)

	if prefix == "tags: " or vim.endswith(prefix, tag_delimiter) then
		log:debug("Running cmp `complete()` function.")
		self.items = db.completion:get()[1]["tag_strings"]
		callback(self.items)
	end
end

return M
