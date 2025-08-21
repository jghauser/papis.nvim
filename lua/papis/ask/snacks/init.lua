--
-- PAPIS | ASK | SNACKS
--
-- Papis Ask Snacks picker

---@module 'snacks'

local config = require("papis.config")
local picker_common = require("papis.ask.picker_common")
local actions = require("papis.ask.snacks.actions")
local utils = require("papis.utils")

local M = {}

---Format an ask entry for display in the picker
---@param item snacks.picker.Item
---@return table display_strings Formatted display strings
function M.format(item, _)
  local display_strings

  local placeholder = item.entry.placeholder
  if placeholder then
    display_strings = { { placeholder, "Comment" }, }
  else
    local entry = item.entry
    local results_format = config["ask"].results_format
    display_strings = utils:format_display_strings(entry, results_format, false, true)
  end

  return display_strings
end

---Preview function for ask entries
---@type snacks.picker.preview
---@param ctx snacks.picker.preview.ctx
function M.preview(ctx)
  picker_common.create_preview(ctx.item.entry, ctx.buf, ctx.win)
end

---Finder function for ask entries
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
  source = "papis-ask",
  finder = M.find,
  format = M.format,
  preview = M.preview,
  win = {
    input = {
      keys = config["ask"].picker_keymaps,
    },
  },
  actions = actions,
}

---Open the ask picker
---@return snacks.Picker The snacks picker instance
function M.picker()
  return Snacks.picker("Papis Ask", M.opts)
end

return M
