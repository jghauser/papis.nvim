--
-- PAPIS | COMPLETION | CMP
--
--
-- The cmp source.
--

---@module 'cmp'

local log = require("papis.log")
local common = assert(require("papis.completion.common"), "Failed to load papis.completion.common")

---@class PapisCompletionCmp : cmp.Source
local M = {}

---Creates a new cmp source
---@return cmp.Source
function M.new()
  return setmetatable({}, { __index = M })
end

---Gets trigger characters
---@return string[]
function M:get_trigger_characters()
  return { " " }
end

---Ensures that this source is only available in info_name files, and only for the "tags" key
---@return boolean is_available True if info_name file, false otherwise
M.is_available = common.is_available

---Completes the current request
---@param request table
---@param callback function
function M:complete(request, callback)
  local prefix = string.sub(request.context.cursor_before_line, 1, request.offset)
  log.debug("Request prefix: " .. prefix)

  -- complete if after tag_delimiter
  local comp_after_tag_delimiter = vim.endswith(prefix, "- ")

  if comp_after_tag_delimiter then
    log.debug("Running cmp completion")
    callback(common.get_completion_items())
  end
end

return M
