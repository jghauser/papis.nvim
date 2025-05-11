--
-- PAPIS | COMPLETION | BLINK
--
--
-- The blink source.
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

local show_on_blocked_trigger_characters_backup = require("blink.cmp.config").completion.trigger
    .show_on_blocked_trigger_characters

--- @module 'blink.cmp completion source'
--- @class papis.completion.blink
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
function M:enabled()
  local is_available = common:is_available()
  -- HACK: there doesn't seem to be a way to set this for an individual source
  if is_available then
    require("blink.cmp.config").completion.trigger.show_on_blocked_trigger_characters = {}
  else
    log.debug("asdasdasdads: " .. vim.inspect(show_on_blocked_trigger_characters_backup))
    require("blink.cmp.config").completion.trigger.show_on_blocked_trigger_characters =
        show_on_blocked_trigger_characters_backup
  end
  return is_available
end

---Completes the current request
---@param ctx table
---@param callback function
function M:get_completions(ctx, callback)
  log.debug("Getting completions")
  local col = ctx.cursor[2] + 1
  local prefix = ctx.line:sub(1, col + 2)

  -- complete if after tag_delimiter
  local comp_after_tag_delimiter = vim.endswith(prefix, common.get_tag_delimiter())
  -- complete if after 'tags: ' keyword and not table tag format
  local comp_after_keyword = (prefix == "tags: ") and not (common.get_tag_delimiter() == "- ")

  if comp_after_tag_delimiter or comp_after_keyword then
    log.debug("Running cmp `complete()` function.")
    local tag_strings = db.completion:get()[1].tag_strings
    --- @type lsp.CompletionItem[]
    local items = {}
    for _, tag in ipairs(tag_strings) do
      --- @type lsp.CompletionItem
      local item = {
        label = tag.label,
      }
      table.insert(items, item)
    end
    callback({
      items = items,
      is_incomplete_backward = false,
      is_incomplete_forward = false,
    })
  else
    callback({})
  end
end

return M
