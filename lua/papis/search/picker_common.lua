--
-- PAPIS | SEARCH | PICKER_COMMON
--
--
-- Common functions for all pickers
--
-- NOTE: functions defined here should act on entries (not picker items)

local config = require("papis.config")
local search_keys = config["search"].search_keys
local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")
local utils = require("papis.utils")
local wrap = config["search"].wrap
local preview_format = config["search"].preview_format

---@class PapisSearchPickerCommon
local M = {}

---Creates a string that is used to search among entries (not displayed)
---@param entry PapisEntry A papis entry
---@return string search_string A string containing all the searchable information
function M.create_search_string(entry)
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

---Find all ask entries for the picker
---@return PapisEntry[] entries List of all entries
function M.load_entries()
  local default_time_added = "1900-01-01-00:00:00"
  local entries = db.data:get()

  if config["search"].initial_sort_by_time_added then
    table.sort(entries, function(a, b)
      local ta = a.time_added or default_time_added
      local tb = b.time_added or default_time_added
      return ta > tb
    end)
  end

  return entries
end

---Creates a preview buffer for the picker
---@param entry PapisEntry The selected entry
---@param buf number The buffer to create the preview in
---@param win number The window to set the preview in
function M.create_preview(entry, buf, win)
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

  local preview_lines = utils:make_nui_lines(preview_format, entry)

  for line_nr, line in ipairs(preview_lines) do
    line:render(buf, -1, line_nr)
  end

  vim.api.nvim_set_option_value("wrap", wrap, { win = win })
  vim.api.nvim_set_option_value("number", false, { win = win })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("spell", false, { win = win })
end

return M
