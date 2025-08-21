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
local telescope_config = require("telescope.config").values

local papis_actions = require("papis.search.telescope.actions")
local config = require("papis.config")
local log = require("papis.log")
local utils = require("papis.utils")
local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")

local wrap = config["search"].wrap
local preview_format = config["search"].preview_format
local initial_sort_by_time_added = config["search"].initial_sort_by_time_added

-- Telescope is quite slow, so we precalculate the relevant values
local telescope_precalc = {}
local precalc_last_updated = 0

local papis_entry_display = {}
local entry_display = require("telescope.pickers.entry_display")
setmetatable(papis_entry_display, { __index = entry_display })
papis_entry_display.truncate = function(a)
  return a
end -- HACK: there must better way to turn this off


---Create a telescope entry for a given db entry
---@param entry table #A entry in the library db
---@return table #A telescope entry
local entry_maker = function(entry)
  local entry_pre_calc = db.search:get(entry.id)[1]
  local timestamp = entry_pre_calc.timestamp
  local items = entry_pre_calc.items

  local displayer_tbl = entry_pre_calc.displayer_tbl
  local displayer = papis_entry_display.create({
    separator = "",
    items = items,
  })

  local make_display = function()
    return displayer(displayer_tbl)
  end

  local search_string = entry_pre_calc.search_string
  return {
    value = search_string,
    ordinal = search_string,
    display = make_display,
    timestamp = timestamp,
    id = entry,
  }
end

---Get precalcuated telescope entries (or create them if they don't yet exist)
---@return table #Table with precalculated telescope entries for all db entries
local function get_precalc()
  local db_last_modified = db.state:get_value({ id = 1 }, "db_last_modified")
  if precalc_last_updated < db_last_modified then
    log.debug("Updating precalc")
    precalc_last_updated = db_last_modified
    telescope_precalc = {}
    local entries = db.data:get()
    for _, entry in ipairs(entries) do
      -- TODO: only update if mtime for entry indicates a recent change
      local id = entry.id
      telescope_precalc[id] = entry_maker(entry)
    end
  end
  return telescope_precalc
end

---Defines the papis search telescope picker
---@param opts table? #Options for the papis picker
local function papis_picker(opts)
  opts = opts or {}

  -- get precalculated entries for the telescope picker
  telescope_precalc = get_precalc()

  -- amend the generic_sorter so that we can change initial sorting
  local generic_sorter = telescope_config.generic_sorter(opts)
  local papis_sorter = {}
  setmetatable(papis_sorter, { __index = generic_sorter })

  if initial_sort_by_time_added then
    ---@param prompt string
    ---@param line string
    ---@return number score number from 1 to 0. lower the number the better. -1 will filter out the entry though.
    function papis_sorter:scoring_function(prompt, line, entry)
      local score = generic_sorter.scoring_function(self, prompt, line)
      if #prompt == 0 then
        local min_timestamp = 0
        local max_timestamp = os.time()
        local timestamp = entry.timestamp

        score = 1 - (timestamp - min_timestamp) / (max_timestamp - min_timestamp)
      end
      return score
    end
  end

  pickers
      .new(opts, {
        prompt_title = "Papis References",
        finder = finders.new_table({
          results = telescope_precalc,
          entry_maker = function(entry)
            return entry
          end,
        }),
        previewer = previewers.new_buffer_previewer({
          define_preview = function(self, entry, status)
            local preview_lines = utils:make_nui_lines(preview_format, entry.id)

            for line_nr, line in ipairs(preview_lines) do
              line:render(self.state.bufnr, -1, line_nr)
            end

            vim.api.nvim_set_option_value("wrap", wrap, { win = status.preview_win })
          end,
        }),
        sorter = papis_sorter,
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
    papis = papis_picker,
  },
}

return M
