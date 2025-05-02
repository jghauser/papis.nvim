--
-- PAPIS | SEARCH
--
-- Initialises the papis.nvim search module.
--

local log = require("papis.log")
local config = require("papis.config")
local commands = require("papis.commands")
local keymaps = require("papis.keymaps")
local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end

local papis_entry_display = {}

local telescope_precalc = {}
local precalc_last_updated = 0

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

---@class PapisSubcommand
local module_subcommands = {
  search = {
    impl = function(_, _)
      if config["search"].provider == "telescope" then
        vim.cmd("Telescope papis")
      elseif config["search"].provider == "snacks" then
        require("papis.search.snacks").picker()
      end
    end,
  },
}

---@class PapisKeymaps
local module_keymaps = {
  open_search_normal = {
    mode = "n",
    lhs = "<leader>pp",
    rhs = function()
      vim.cmd("Papis search")
    end,
    opts = { desc = "Papis: search library" },
  },
  open_search_insert = {
    mode = "i",
    lhs = "<c-o>p",
    rhs = function()
      vim.cmd("Papis search")
    end,
    opts = { desc = "Papis: search library" },
  },
}

local M = {}

---Get precalcuated telescope entries (or create them if they don't yet exist)
---@return table #Table with precalculated telescope entries for all db entries
function M.get_precalc()
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

---Sets up the papis.nvim picker
function M.setup()
  log.debug("Search: setting up module")
  require("papis.search.data").init()
  if config["search"].provider == "telescope" then
    local has_telescope, telescope = pcall(require, "telescope")
    if not has_telescope then
      error("The plugin telescope.nvim wasn't found but the search module is enabled and requires it.")
    end

    local entry_display = require("telescope.pickers.entry_display")
    setmetatable(papis_entry_display, { __index = entry_display })
    papis_entry_display.truncate = function(a)
      return a
    end -- HACK: there must better way to turn this off

    telescope.setup({
      extensions = {
        papis = config["search"],
      },
    })
    telescope.load_extension("papis")
    commands:add_commands(module_subcommands)
    keymaps:add_keymaps(module_keymaps)
  elseif config["search"].provider == "snacks" then
    local has_snacks, _ = pcall(require, "snacks")
    if not has_snacks then
      error("The plugin snacks.nvim wasn't found but the search module is enabled and requires it.")
    end

    commands:add_commands(module_subcommands)
    keymaps:add_keymaps(module_keymaps)
  else
    error("The search module is enabled but no valid provider was specified.")
  end
end

return M
