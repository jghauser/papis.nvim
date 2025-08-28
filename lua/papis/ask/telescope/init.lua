--
-- PAPIS | ASK | TELESCOPE | INIT
--
-- Papis ask telescope picker
--
-- NOTE: an *item* is a picker item, an *entry* is a question/answer item

local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local previewers = require("telescope.previewers")

local picker_common = require("papis.ask.picker_common")
local config = require("papis.config")
local log = require("papis.log")
local utils = require("papis.utils")

local results_format = config["ask"].results_format

local custom_item_display = {}
local item_display = require("telescope.pickers.entry_display")
setmetatable(custom_item_display, { __index = item_display })
custom_item_display.truncate = function(a)
  return a
end -- HACK: there must better way to turn this off

---Creates a single telescope entry
---@param entry PapisAskEntry A single question/answer entry
---@return TelescopeItem #A telescope item
local item_maker = function(entry)
  local display_strings = utils:format_display_strings(entry, results_format, false, true)
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

  local search_string = picker_common.create_search_string(entry)

  return {
    value = search_string,
    ordinal = search_string,
    display = function()
      return displayer(displayer_tbl)
    end,
    entry = entry,
  }
end

---@class PapisAskTelescope
local M = {}

---Create telescope items
---@return TelescopeItem[] items A list of items for the telescope papis ask picker
function M.get_items()
  local entries = picker_common.load_entries()
  local items = {}
  if entries[1].placeholder then
    items[#items + 1] = {
      ordinal = 1,
      display = entries[1].placeholder,
      entry = entries[1]
    }
  else
    log.debug("there are entries")
    for _, entry in ipairs(entries) do
      log.debug(vim.inspect(entry))
      items[#items + 1] = item_maker(entry)
    end
  end
  return items
end

---Defines the papis ask telescope picker
---@param opts table? Options for the telescope papis ask picker
local function papis_ask_picker(opts)
  opts = opts or {}

  pickers.new({}, {
    prompt_title = 'Papis ask',
    finder = finders.new_table({
      results = M.get_items(),
      entry_maker = function(item)
        return item
      end,
    }),
    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, item, status)
        picker_common.create_preview(item.entry, self.state.bufnr, status.preview_win)
      end,
    }),
    attach_mappings = function(prompt_bufnr, map)
      local papis_actions = require("papis.ask.telescope.actions")
      local actions = require("telescope.actions")
      actions.select_default:replace(function()
        papis_actions.open_answer(prompt_bufnr)
      end)
      for key, mapping_config in pairs(config.ask.picker_keymaps) do
        local action_name = mapping_config[1]
        local modes = mapping_config.mode
        local desc = mapping_config.desc or ""
        map(modes, key, function()
          papis_actions[action_name](prompt_bufnr)
        end, { desc = desc })
      end
      return true
    end,
  }):find()
end

M.exports = {
  papis_ask = papis_ask_picker,
}

return M
