--
-- PAPIS | SEARCH | TELESCOPE
--
--
-- Papis Telescope picker
--
-- Adapted from: https://github.com/nvim-telescope/telescope-bibtex.nvim

local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local previewers = require("telescope.previewers")

local papis_actions = require("papis.search.telescope.actions")
local config = require("papis.config")
local log = require("papis.log")
local utils = require("papis.utils")
local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")
local picker_common = assert(require("papis.search.picker_common"), "Failed to load papis.search.picker_common")

-- NOTE: an *item* is a picker item, an *entry* is a question/answer item

local results_format = config["search"].results_format

-- Telescope is quite slow, so we precalculate the relevant values
local telescope_precalc_items = {}
local precalc_last_updated = 0


local custom_item_display = {}
local item_display = require("telescope.pickers.entry_display")
setmetatable(custom_item_display, { __index = item_display })
custom_item_display.truncate = function(a)
  return a
end -- HACK: there must better way to turn this off

---Create a telescope item for a given db entry
---@param entry table #A entry in the library db
---@return table #A telescope entry
local item_maker = function(entry)
  local display_strings = utils:format_display_strings(entry, results_format, false, true)
  local search_string = picker_common.create_search_string(entry)
  log.debug("search_string: " .. search_string)

  local items = {}
  local displayer_tbl = {}
  for _, vv in ipairs(display_strings) do
    items[#items + 1] = { width = vim.fn.strdisplaywidth(vv[1], 1) }
    displayer_tbl[#displayer_tbl + 1] = { vv[1], vv[2] }
  end
  items[#items + 1] = { remaining = true }

  local displayer = custom_item_display.create({
    separator = "",
    items = items,
  })

  return {
    value = search_string,
    ordinal = search_string,
    display = function()
      return displayer(displayer_tbl)
    end,
    entry = entry,
  }
end

---Get precalcuated telescope entries (or create them if they don't yet exist)
---@return table #Table with precalculated telescope entries for all db entries
local function get_precalc_items()
  local db_last_modified = db.state:get_value({ id = 1 }, "db_last_modified")
  if precalc_last_updated < db_last_modified then
    log.debug("Updating precalc")
    precalc_last_updated = db_last_modified
    telescope_precalc_items = {}
    local entries = picker_common.load_entries()
    for _, entry in ipairs(entries) do
      telescope_precalc_items[#telescope_precalc_items + 1] = item_maker(entry)
    end
  end

  return telescope_precalc_items
end

---Defines the papis search telescope picker
---@param opts table? #Options for the papis picker
local function papis_search_picker(opts)
  opts = opts or {}

  -- get precalculated entries for the telescope picker
  local items = get_precalc_items()

  pickers
      .new(opts, {
        prompt_title = "Papis search",
        finder = finders.new_table({
          results = items,
          entry_maker = function(item)
            return item
          end,
        }),
        previewer = previewers.new_buffer_previewer({
          define_preview = function(self, item, status)
            picker_common.create_preview(item.entry, self.state.bufnr, status.preview_win)
          end,
        }),
        -- sorter = papis_sorter,
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            papis_actions.ref_insert(prompt_bufnr)
          end)
          -- Process mappings from config
          for key, mapping_config in pairs(config.search.picker_keymaps) do
            local action_name = mapping_config[1]
            local modes = mapping_config.mode
            local desc = mapping_config.desc or ""
            map(modes, key, function()
              papis_actions[action_name](prompt_bufnr)
            end, { desc = desc })
          end
          return true
        end,
      })
      :find()
end

local M = {
  exports = {
    papis_ask = papis_search_picker,
  },
}

return M
