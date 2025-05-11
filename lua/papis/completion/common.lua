--
-- PAPIS | COMPLETION | COMMON
--
--
-- Common resources used by different providers.
--

local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end
local log = require("papis.log")
local ts = vim.treesitter
local Path = require("pathlib")
local api = vim.api

local tag_delimiter

-- Mapping table for tag delimiters
local tag_delimiters = {
  tbl = "- ",
  [","] = ", ",
  [";"] = "; ",
  [" "] = " ",
}

local parse_query = ts.query.parse(
  "yaml",
  [[
  (block_mapping_pair
    key: (flow_node) @name (#eq? @name "tags")
  ) @capture
  ]]
)


local M = {}

---Gets the tag delimiter
---@return string #tag_delimiter
function M.get_tag_delimiter()
  if not tag_delimiter then
    local tag_format = db.state:get_value({ id = 1 }, "tag_format")
    tag_delimiter = tag_delimiters[tag_format]
    log.debug("Tag delimiter: " .. tag_delimiter)
  end
  return tag_delimiter
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

  local info_name = db.config:get_conf_value("info_name")
  if filename == info_name then
    log.trace("we are in a papis info file")

    if M.get_tag_delimiter() then
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

return M
