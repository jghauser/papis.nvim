--
-- PAPIS | COMPLETION | CMP
--
--
-- The cmp source.
--

local log = require("papis.log")
local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")
local common = assert(require("papis.completion.common"), "Failed to load papis.completion.common")

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
    log.debug("Running cmp `complete()` function.")
    self.items = db.completion:get()[1].tag_strings
    callback(self.items)
  end
end

return M
