--
-- PAPIS | SEARCH | DATA
--
--
-- Defines the sqlite table and associated methods for the search module.
--

local db = require("papis.sqlite-wrapper")
if not db then
  return nil
end
local config = require("papis.config")
local search_keys = config["search"]["search_keys"]
local preview_format = config["search"]["preview_format"]
local results_format = config["search"]["results_format"]
local utils = require("papis.utils")
local required_db_keys = utils:get_required_db_keys({ search_keys, preview_format, results_format })

---Creates a string that is used to search among entries (not displayed)
---@param entry table #A papis entry
---@return string #A string containing all the searchable information
local function format_search_string(entry)
  local function do_incl_str(k_in_entry, k_in_conf_keys)
    k_in_conf_keys = k_in_conf_keys or k_in_entry
    if entry[k_in_entry] and vim.tbl_contains(search_keys, k_in_conf_keys) then
      return true
    end
    return false
  end

  local str_elements = {}
  if do_incl_str("author") then
    table.insert(str_elements, entry["author"])
  elseif do_incl_str("editor", "author") then
    table.insert(str_elements, entry["editor"])
  end
  if do_incl_str("year") then
    table.insert(str_elements, entry["year"])
  end
  if do_incl_str("title") then
    table.insert(str_elements, entry["title"])
  end
  if do_incl_str("type") then
    table.insert(str_elements, entry["type"])
  end
  if do_incl_str("tags") then
    table.insert(str_elements, table.concat(entry["tags"], " "))
  end
  local search_string = table.concat(str_elements, " ")
  return search_string
end

---Initialises all the tables and methods used by the papis.nvim search module
local function init_tbl()
  db.search = db:tbl("search", {
    id = true,
    items = { "luatable" },
    displayer_tbl = { "luatable" },
    search_string = { "text" },
    entry = {
      type = "integer",
      unique = true,
      reference = "data.id",
      on_update = "cascade",
      on_delete = "cascade",
    },
  })

  ---Gets the contents of search tbl for given id
  ---@param id number #The id of a papis entry
  ---@return table #Has structure {{ tbl_key = tbl_val, ... }}
  function db.search:get(id)
    return self:__get({
      where = { id = id },
      select = {
        "items",
        "displayer_tbl",
        "search_string",
      },
    })
  end

  ---Updates the tbl for a given id
  ---@param id number #The id of a papis entry
  function db.search:update(id)
    local entry = db["data"]:__get({
      where = { id = id },
      select = required_db_keys,
    })[1]
    local display_strings = utils:format_display_strings(entry, results_format)
    local search_string = format_search_string(entry)

    local items = {}
    local displayer_tbl = {}
    for _, vv in ipairs(display_strings) do
      table.insert(items, { width = vim.fn.strdisplaywidth(vv[1], 1) })
      table.insert(displayer_tbl, { vv[1], vv[2] })
    end
    table.insert(items, { remaining = true })

    self:__update({
      where = { id = id },
      set = {
        displayer_tbl = displayer_tbl,
        items = items,
        search_string = search_string,
        entry = id,
      },
    })
  end
end

local M = {}

M.opts = { has_row_for_each_main_tbl_row = true }

---Initialises the search data functions
function M.init()
  init_tbl()
end

return M
