--
-- PAPIS | SEARCH | SNACKS
--
-- Papis Snacks picker

---@module 'snacks'

local config_search = require("papis.config")["search"]
local utils = require("papis.utils")
local db = require("papis.sqlite-wrapper")
local actions = require("papis.search.snacks.actions")

local M = {}

function M.find()
  -- local precalc = require("papis.search").get_precalc()
  local precalc = db.data:get()
  return vim.tbl_map(function(entry)
    return {
      entry = entry,
      text = entry.author .. " " .. entry.year .. " " .. entry.title,
    }
  end, precalc)
end

---@param item snacks.picker.Item
function M.format(item, _)
  local entry = item.entry
  local fstr = utils:format_display_strings(entry, config_search.results_format)
  return fstr
end

---@type snacks.picker.preview
function M.preview(ctx)
  local entry = ctx.item.entry
  local preview_lines = utils:make_nui_lines(config_search.preview_format, entry)

  vim.bo[ctx.buf].modifiable = true
  for line_nr, line in ipairs(preview_lines) do
    line:render(ctx.buf, -1, line_nr)
  end
  vim.bo[ctx.buf].modifiable = false
end

---@type snacks.picker.Config
M.opts = {
  source = "test",
  finder = M.find,
  format = M.format,
  preview = M.preview,
  win = {
    input = {
      keys = {
        ["<CR>"] = { "ref_insert", mode = { "n", "i" }, desc = "(Papis) Insert ref" },
        ["<C-R>"] = { "ref_insert_formatted", mode = { "n", "i" }, desc = "(Papis) Insert formatted ref" },
        ["<C-F>"] = { "open_file", mode = { "n", "i" }, desc = "(Papis) Open file" },
        ["<C-N>"] = { "open_note", mode = { "n", "i" }, desc = "(Papis) Open note" },
        ["<C-E>"] = { "open_info", mode = { "n", "i" }, desc = "(Papis) Open info.yaml file" },
      },
    },
  },
  actions = actions,
}

function M.picker()
  return Snacks.picker("Papis", M.opts)
end

return M
