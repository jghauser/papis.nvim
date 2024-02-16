--
-- PAPIS | TELESCOPE
--
--
-- Papis Telescope picker
--
-- Adapted from: https://github.com/nvim-telescope/telescope-bibtex.nvim

local telescope = require("telescope")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local previewers = require("telescope.previewers")
local telescope_config = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local papis_actions = require("telescope._extensions.papis.actions")

local utils = require("papis.utils")
local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end

local wrap, preview_format, required_db_keys

---Gets the cite format for the filetype
---@return string #The cite format for the filetype (or fallback if undefined)
local function parse_format_string()
  local cite_format = utils.get_cite_format(vim.bo.filetype)
  if type(cite_format) == "table" then
    cite_format = cite_format[1]
  end
  return cite_format
end

---Defines the papis.nvim telescope picker
---@param opts table #Options for the papis picker
local function papis_picker(opts)
  opts = opts or {}

  local results = db.data:get(nil, required_db_keys)
  local format_string = parse_format_string()
  pickers
    .new(opts, {
      prompt_title = "Papis References",
      finder = finders.new_table({
        results = results,
        entry_maker = function(entry)
          local entry_pre_calc = db["search"]:get(entry["id"])[1]
          local items = entry_pre_calc["items"]

          local displayer_tbl = entry_pre_calc["displayer_tbl"]

          local displayer = entry_display.create({
            separator = "",
            items = items,
          })

          local make_display = function()
            return displayer(displayer_tbl)
          end

          local search_string = entry_pre_calc["search_string"]
          return {
            value = search_string,
            ordinal = search_string,
            display = make_display,
            id = entry,
          }
        end,
      }),
      previewer = previewers.new_buffer_previewer({
        define_preview = function(self, entry, status)
          local previewer_entry = vim.deepcopy(entry)
          local clean_preview_format = utils.do_clean_format_tbl(preview_format, previewer_entry.id)

          -- get only file names (not full path)
          if previewer_entry.id.notes then
            previewer_entry.id.notes = utils.get_filenames(previewer_entry.id.notes)
          end
          if previewer_entry.id.files then
            previewer_entry.id.files = utils.get_filenames(previewer_entry.id.files)
          end

          local preview_lines = utils.make_nui_lines(clean_preview_format, previewer_entry.id)

          for line_nr, line in ipairs(preview_lines) do
            line:render(self.state.bufnr, -1, line_nr)
          end

          vim.api.nvim_win_set_option(status.preview_win, "wrap", wrap)
        end,
      }),
      sorter = telescope_config.generic_sorter(opts),
      attach_mappings = function(_, map)
        actions.select_default:replace(papis_actions.ref_insert(format_string))
        map("i", "<c-o>f", papis_actions.open_file())
        map("n", "of", papis_actions.open_file())
        map("i", "<c-o>n", papis_actions.open_note())
        map("n", "on", papis_actions.open_note())
        map("i", "<c-e>", papis_actions.open_info())
        map("n", "e", papis_actions.open_info())
        map("n", "f", papis_actions.ref_insert_formatted(), {desc="insert formatted reference"})
        map("i", "<c-f>", papis_actions.ref_insert_formatted(), {desc="insert formatted reference"})
        -- Makes sure that the other defaults are still applied
        return true
      end,
    })
    :find()
end

return telescope.register_extension({
  setup = function(opts)
    wrap = opts["wrap"]
    preview_format = opts["preview_format"]
    local search_keys = opts["search_keys"]
    local results_format = opts["results_format"]
    required_db_keys = utils:get_required_db_keys({ { "papis_id" }, search_keys, preview_format, results_format })
  end,
  exports = {
    papis = papis_picker,
  },
})
