--
-- PAPIS | COMPLETION | COMMON
--
--
-- Common resources used by different providers.
--

local fs = vim.fs

local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")
local log = require("papis.log")
local ts = vim.treesitter
local api = vim.api

---@type vim.treesitter.Query
local parse_query = ts.query.parse(
  "yaml",
  [[
  (block_mapping_pair
    key: (flow_node) @name (#eq? @name "tags")
  ) @capture
  ]]
)

---@class PapisCompletionCommon
local M = {}

---@class CompletionItem
---@field word string
---@field label string

---Makes a list of all tags
---@return CompletionItem[] #List of completion items
function M.get_completion_items()
  local seen_tags = {}
  local completion_items = {}
  local result = db.data:get(nil, { "tags" })
  for i = 1, #result do
    local tags = result[i].tags
    if tags then
      for j = 1, #tags do
        local tag = tags[j]
        if not seen_tags[tag] then
          seen_tags[tag] = true
          completion_items[#completion_items + 1] = {
            word = tag,
            label = tag,
          }
        end
      end
    end
  end
  return completion_items
end

---Ensures that this source is only available in info_name files, and only for the "tags" key
---@return boolean is_available True if info_name file, false otherwise
function M.is_available()
  local is_available = false
  local current_filepath = api.nvim_buf_get_name(0)
  local filename = fs.basename(current_filepath)

  local info_name = db.config:get_conf_value("info_name")
  if filename == info_name then
    log.trace("we are in a papis info file")

    local parser = ts.get_parser(0, "yaml")
    assert(parser, "No parser found for yaml. Please ensure you have the yaml treesitter parser installed.")
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
          -- Check if current character is a dash and if it's at the beginning of a line
          log.trace("completion is available")
          is_available = true
        end
      end
    end
  end
  return is_available
end

return M
