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
local search_keys = config["search"].search_keys
local results_format = config["search"].results_format
local utils = require("papis.utils")

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
    str_elements[#str_elements + 1] = entry.author
  elseif do_incl_str("editor", "author") then
    str_elements[#str_elements + 1] = entry.editor
  end
  if do_incl_str("year") then
    str_elements[#str_elements + 1] = entry.year
  end
  if do_incl_str("title") then
    str_elements[#str_elements + 1] = entry.title
  end
  if do_incl_str("type") then
    str_elements[#str_elements + 1] = entry.type
  end
  if do_incl_str("tags") then
    str_elements[#str_elements + 1] = table.concat(entry.tags, " ")
  end
  local search_string = table.concat(str_elements, " ")
  return search_string
end

---Creates a timestamp (in secs since epoch), which is used for initial sorting
---@param entry table #A papis entry
---@return integer #The timestamp (date when entry was added in secs since epoch or 1 if missing)
local function make_timestamp(entry)
  local timestamp = entry.time_added
  if timestamp then
    local year, month, day, hour, min, sec = timestamp:match("(%d+)-(%d+)-(%d+)-(%d+):(%d+):(%d+)")
    local t = { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
    timestamp = os.time(t)
  else
    timestamp = 1
  end
  return timestamp
end

---Initialises all the tables and methods used by the papis.nvim search module
local function init_tbl()
  db.search = db:tbl("search", {
    id = true,
    items = { "luatable" },
    displayer_tbl = { "luatable" },
    search_string = { "text" },
    timestamp = { "integer" },
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
        "timestamp",
      },
    })
  end

  ---Updates the tbl for a given id
  ---@param id number #The id of a papis entry
  function db.search:update(id)
    local entry = db.data:__get({
      where = { id = id }
    })[1]
    local display_strings = utils:format_display_strings(entry, results_format, false, true)
    local search_string = format_search_string(entry)

    local items = {}
    local displayer_tbl = {}
    for _, vv in ipairs(display_strings) do
      items[#items + 1] = { width = vim.fn.strdisplaywidth(vv[1], 1) }
      displayer_tbl[#displayer_tbl + 1] = { vv[1], vv[2] }
    end
    items[#items + 1] = { remaining = true }

    local timestamp = make_timestamp(entry)

    self:__update({
      where = { id = id },
      set = {
        displayer_tbl = displayer_tbl,
        items = items,
        search_string = search_string,
        timestamp = timestamp,
        entry = id,
      },
    })

    require("papis.search").update_precalc(entry)
  end
end

local M = {}

M.opts = { has_row_for_each_main_tbl_row = true }

---Initialises the search data functions
function M.init()
  init_tbl()
end

return M
