--
-- PAPIS | SEARCH | SNACKS
--
-- Papis Snacks picker
--
-- NOTE: an *item* is a picker item, an *entry* is a papis entry

---@module 'snacks'

local config = require("papis.config")
local utils = require("papis.utils")
local actions = require("papis.search.snacks.actions")
local picker_common = assert(require("papis.search.picker_common"), "Failed to load papis.search.picker_common")

---@class PapisSearchSnacks
local M = {}

---Format a search entry for display in the picker
---@type snacks.picker.format
---@param item snacks.picker.Item
---@return PapisDisplayStrings display_strings Formatted display strings
function M.format(item, _)
  local entry = item.entry
  local results_format = config["search"].results_format
  local display_strings = utils:format_display_strings(entry, results_format, false, true)
  return display_strings
end

---Preview function for search entries
---@type snacks.picker.preview
---@param ctx snacks.picker.preview.ctx
function M.preview(ctx)
  picker_common.create_preview(ctx.item.entry, ctx.buf, ctx.win)
end

---Finder function for search entries
---@type snacks.picker.finder
---@return snacks.picker.Item[] items List of items for the picker
function M.find()
  local entries = picker_common.load_entries()

  local items = vim.tbl_map(function(entry)
    return {
      entry = entry,
      text = picker_common.create_search_string(entry),
    }
  end, entries)

  return items
end

---@type snacks.picker.Config Snacks picker configuration
M.opts = {
  source = "papis-search",
  finder = M.find,
  format = M.format,
  preview = M.preview,
  win = {
    input = {
      ---@diagnostic disable-next-line: assign-type-mismatch
      keys = config["search"].picker_keymaps,
    },
  },
  actions = actions,
}

---Open the search picker
---@return snacks.Picker #The snacks picker instance
function M.picker()
  return Snacks.picker("Papis search", M.opts)
end

return M
