--
-- PAPIS | SEARCH | SNACKS
--
-- Papis Snacks picker

---@module 'snacks'

local config = require("papis.config")
local utils = require("papis.utils")
local db = require("papis.sqlite-wrapper")
local actions = require("papis.search.snacks.actions")

local M = {}

function M.find()
  local precalc = db.data:get()
  return vim.tbl_map(function(entry)
    local entry_pre_calc = db.search:get(entry.id)[1]
    return {
      entry = entry,
      text = entry_pre_calc.search_string
    }
  end, precalc)
end

---@param item snacks.picker.Item
function M.format(item, _)
  local entry_pre_calc = db.search:get(item.entry.id)[1]
  local fstr = entry_pre_calc.displayer_tbl
  return fstr
end

---@type snacks.picker.preview
function M.preview(ctx)
  local entry = ctx.item.entry
  local preview_lines = utils:make_nui_lines(config["search"].preview_format, entry)

  vim.bo[ctx.buf].modifiable = true
  for line_nr, line in ipairs(preview_lines) do
    line:render(ctx.buf, -1, line_nr)
  end
  vim.bo[ctx.buf].modifiable = false
end

---@type snacks.picker.Config
M.opts = {
  source = "papis",
  finder = M.find,
  format = M.format,
  preview = M.preview,
  win = {
    input = {
      keys = config["search"].snacks_picker_keymaps,
    },
  },
  actions = actions,
}

function M.picker()
  return Snacks.picker("Papis References", M.opts)
end

return M
