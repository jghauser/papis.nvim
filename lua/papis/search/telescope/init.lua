--
-- PAPIS | SEARCH | TELESCOPE
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
-- local papis_actions = require("telescope._extensions.papis.actions")
local papis_actions = require("papis.search.telescope.actions")

local utils = require("papis.utils")
local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end

local wrap, preview_format, initial_sort_by_time_added

---Defines the papis.nvim telescope picker
---@param opts table #Options for the papis picker
local function papis_picker(opts)
  opts = opts or {}

  -- get precalculated entries for the telescope picker
  local telescope_precalc = require("papis.search").get_precalc()

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
        map("i", "<c-f>", function()
          papis_actions.open_file(prompt_bufnr)
        end, { desc = "Open file" })
        map("n", "f", function()
          papis_actions.open_file(prompt_bufnr)
        end, { desc = "Open file" })
        map("i", "<c-n>", function()
          papis_actions.open_note(prompt_bufnr)
        end, { desc = "Open note" })
        map("n", "n", function()
          papis_actions.open_note(prompt_bufnr)
        end, { desc = "Open note" })
        map("i", "<c-e>", function()
          papis_actions.open_info(prompt_bufnr)
        end, { desc = "Open info.yaml file" })
        map("n", "e", function()
          papis_actions.open_info(prompt_bufnr)
        end, { desc = "Open info.yaml file" })
        map("n", "r", function()
          papis_actions.ref_insert_formatted(prompt_bufnr)
        end, { desc = "Insert formatted reference" })
        map("i", "<c-r>", function()
          papis_actions.ref_insert_formatted(prompt_bufnr)
        end, { desc = "Insert formatted reference" })
        -- Makes sure that the other defaults are still applied
        return true
      end,
    })
    :find()
end

return telescope.register_extension({
  setup = function(opts)
    wrap = opts.wrap
    initial_sort_by_time_added = opts.initial_sort_by_time_added
    preview_format = opts.preview_format
  end,
  exports = {
    papis = papis_picker,
  },
})
