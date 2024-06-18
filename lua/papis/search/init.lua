--
-- PAPIS | SEARCH
--
-- Initialises the papis.nvim search module.
--

local log = require("papis.log")
local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  log.error("The plugin telescope.nvim wasn't found but the search module is enabled and requires it.")
  return nil
end
local entry_display = require("telescope.pickers.entry_display")
entry_display.truncate = function(a) return a end -- HACK: there must better way to turn this off
local config = require("papis.config")
local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end

local telescope_precalc = {}

local entry_maker = function(entry)
  local entry_pre_calc = db["search"]:get(entry["id"])[1]
  local timestamp = entry_pre_calc["timestamp"]
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
    timestamp = timestamp,
    id = entry,
  }
end

local M = {}

function M.update_precalc(entry)
  local id = entry["id"]
  telescope_precalc[id] = entry_maker(entry)
end

function M.get_precalc()
  if vim.tbl_isempty(telescope_precalc) then
    local entries = db.data:get()
    for _, entry in ipairs(entries) do
      local id = entry["id"]
      telescope_precalc[id] = entry_maker(entry)
    end
  end
  return telescope_precalc
end

---Sets up the papis.nvim telescope extension
function M.setup()
  log.debug("Search: setting up module")
  require("papis.search.data").init()
  telescope.setup({
    extensions = {
      papis = config["search"],
    },
  })
  telescope.load_extension("papis")
end

return M
