--
-- PAPIS | COMPLETION | CMP
--
--
-- The cmp source.
--

local log = require("papis.log")
local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end
local common = require("papis.completion.common")
if not common then
  return nil
end

--- @module 'cmp-nvim completion source'
--- @class papis.completion.cmp
local M = {}

---Creates a new cmp source
---@return table
function M.new()
  return setmetatable({}, { __index = M })
end

---Gets trigger characters
---@return table
M.get_trigger_characters = common.get_trigger_characters

---Ensures that this source is only available in info_name files, and only for the "tags" key
---@return boolean #True if info_name file, false otherwise
function M:is_available()
  local is_available = common:is_available()
  return is_available
end

---Completes the current request
---@param request table
---@param callback function
function M:complete(request, callback)
  log.debug("offset: " .. request.offset)
  local prefix = string.sub(request.context.cursor_before_line, 1, request.offset)
  log.debug("Request prefix: " .. prefix)

  -- complete if after tag_delimiter
  local comp_after_tag_delimiter = vim.endswith(prefix, common.get_tag_delimiter())
  -- complete if after 'tags: ' keyword and not table tag format
  local comp_after_keyword = (prefix == "tags: ") and not (common.get_tag_delimiter() == "- ")

  if comp_after_tag_delimiter or comp_after_keyword then
    log.debug("Running cmp `complete()` function.")
    self.items = db.completion:get()[1].tag_strings
    callback(self.items)
  end
end

return M
