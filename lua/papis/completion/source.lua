--
-- PAPIS | COMPLETION | SOURCE
--
--
-- The cmp source.
--

local Path = require("pathlib")
local ts = vim.treesitter
local api = vim.api

local log = require("papis.log")
local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end
local tag_delimiter

-- Mapping table for tag delimiters
local tag_delimiters = {
  tbl = "- ",
  [","] = ", ",
  [";"] = "; ",
  [" "] = " ",
}

---Gets tag_delimiter for the tag_format
---@return string|nil #The delimiter between tags given the format
local function get_tag_delimiter()
  local tag_format = db.state:get_value({ id = 1 }, "tag_format")
  -- Use the mapping table to get the tag_delimiter
  tag_delimiter = tag_delimiters[tag_format]
  return tag_delimiter
end

local parse_query = ts.query.parse(
  "yaml",
  [[
  (block_mapping_pair
    key: (flow_node) @name (#eq? @name "tags")
  ) @capture
  ]]
)

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
  local current_filepath = Path(api.nvim_buf_get_name(0))
  local filename = current_filepath:basename()

  local info_name = db.config:get_value({ id = 1 }, "info_name")
  if filename == info_name then
    log.trace("we are in a papis info file")
    if not tag_delimiter then
      tag_delimiter = get_tag_delimiter()
    end

    if tag_delimiter then
      local parser = ts.get_parser(0, "yaml")
      local root = parser:parse()[1]:root()
      local start_row, _, _, end_row, _, _ = unpack(ts.get_range(root))
      local cur_row, _ = unpack(api.nvim_win_get_cursor(0))
      -- check all captured nodes
      for id, node, _ in parse_query:iter_captures(root, 0, start_row, end_row) do
        local name = parse_query.captures[id]
        -- check if the capture is named "capture" (see query above)
        if name == "capture" then
          local node_start, _, _, node_end, _, _ = unpack(ts.get_range(node))
          log.trace("start_line: " .. node_start .. "; cur_line: " .. cur_row .. "; end_line: " .. node_end)
          -- check if cursor line is within captured node
          if node_start <= cur_row and (node_end + 1) >= cur_row then
            log.trace("completion is available")
            is_available = true
          end
        end
      end
    end
  end
  return is_available
end

---Completes the current request
---@param request table
---@param callback function
function M:complete(request, callback)
  local prefix = string.sub(request.context.cursor_before_line, 1, request.offset)
  log.debug("Request prefix: " .. prefix)

  -- complete if after tag_delimiter
  local comp_after_tag_delimiter = vim.endswith(prefix, tag_delimiter)
  -- complete if after 'tags: ' keyword and not table tag format
  local comp_after_keyword = (prefix == "tags: ") and not (tag_delimiter == "- ")

  if comp_after_tag_delimiter or comp_after_keyword then
    log.debug("Running cmp `complete()` function.")
    self.items = db.completion:get()[1]["tag_strings"]
    callback(self.items)
  end
end

return M
