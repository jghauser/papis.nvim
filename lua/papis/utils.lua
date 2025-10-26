--
-- PAPIS | UTILS
--
--
-- Various utility functions used throughout the plugin.
--

---@module 'nui'

local NuiLine = require("nui.line")

local uv = vim.uv
local fs = vim.fs

local log = require("papis.log")

local related_entries_results_format = {
  { "author", "%s ",   "PapisResultsAuthor" },
  { "year",   "(%s) ", "PapisResultsYear" },
  { "title",  "%s",    "PapisResultsTitle" },
}

---@class PapisUtils
local M = {}

local function make_related_to_string(entry)
  local display_strings = M:format_display_strings(entry, related_entries_results_format, true, true)
  local reference = ""
  for _, part in ipairs(display_strings) do
    reference = reference .. part[1]
  end
  return reference
end

---Splits string and trims whitespace
---@param inputstr string String to be split
---@param sep? string String giving each character by which to split
---@return string[] string_parts List of split elements
function M.do_split_str(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local string_parts = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    str = str:match("^()%s*$") and "" or str:match("^%s*(.*%S)")
    string_parts[#string_parts + 1] = str
  end
  return string_parts
end

-- Open file outside neovim
---@param path string Path to the file
function M:do_open_file_external(path)
  local opentool = require("papis.sqlite-wrapper").config:get_conf_value("opentool")
  local opentool_table = self.do_split_str(opentool, " ")
  local command = table.remove(opentool_table, 1)
  local args = opentool_table
  args[#args + 1] = path

  local handle
  ---@diagnostic disable-next-line: missing-fields
  handle = uv.spawn(command, {
    args = args,
    stdio = { nil, nil, nil }
  }, vim.schedule_wrap(function()
    if handle then
      handle:close()
    end
  end))
end

---Gets the file names given a list of full paths
---@param full_paths string[]? A list of paths or nil
---@return string[] filenames A list of file names
function M.get_filenames(full_paths)
  local filenames = {}
  if full_paths then
    for _, full_path in ipairs(full_paths) do
      local filename = fs.basename(full_path)
      filenames[#filenames + 1] = filename
    end
  end
  return filenames
end

---Open an entry's attached files
---@param papis_id string The `papis_id` of the entry
function M:do_open_attached_files(papis_id)
  local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")
  local entry = db.data:get({ papis_id = papis_id }, { "files", "id", "related_to" })[1]
  local filenames = self.get_filenames(entry.files)
  local lookup_tbl = {}
  for k, filename in ipairs(filenames) do
    lookup_tbl[filename] = entry.files[k]
  end
  if vim.tbl_isempty(filenames) then
    if entry.related_to and not vim.tbl_isempty(entry.related_to) then
      local related_entries_with_files = {}
      for _, related_papis_id in ipairs(entry.related_to) do
        local related_entry = db.data:get({ papis_id = related_papis_id }, nil)[1]
        local related_filenames = self.get_filenames(related_entry.files)
        if not vim.tbl_isempty(related_filenames) then
          table.insert(related_entries_with_files, related_entry)
        end
      end
      if #related_entries_with_files == 0 then
        vim.notify("This entry and its related entries have no attached files.",
          vim.log.levels.WARN)
        return
      end

      local items = {}
      for _, related_entry in ipairs(related_entries_with_files) do
        table.insert(items, { label = make_related_to_string(related_entry), entry = related_entry })
      end

      vim.ui.select(items, {
        prompt = "Select a related entry to open its attached files:",
        format_item = function(item) return item.label end,
      }, function(choice)
        if choice then
          self:do_open_attached_files(choice.entry.papis_id)
        end
      end)
    else
      vim.notify("This entry has no attached files.", vim.log.levels.WARN)
    end
  elseif #filenames == 1 then
    log.info(string.format("Opening file '%s' ", filenames[1]))
    local path = lookup_tbl[filenames[1]]
    self:do_open_file_external(path)
  else
    vim.ui.select(filenames, {
      prompt = "Select attachment to open:",
    }, function(choice)
      if choice then
        log.info(string.format("Opening file '%s' ", choice))
        local path = lookup_tbl[choice]
        self:do_open_file_external(path)
      end
    end)
  end
end

---Opens a text file with neovim, asking to select one if there are multiple buf_options
---@param papis_id string The `papis_id` of the entry
---@param type "note"|"info" Specifies the type of file
function M:do_open_text_file(papis_id, type)
  local db = assert(require("papis.sqlite-wrapper"), "Failed to load papis.sqlite-wrapper")
  log.debug("Opening a text file")
  local entry = db.data:get({ papis_id = papis_id }, { "notes", "id", "ref" })[1]
  local info_path = db.metadata:get_value({ entry = entry.id }, "path")
  log.debug("Text file in folder: " .. info_path)
  local cmd = ""
  if type == "note" then
    log.debug("Opening a note")
    if entry.notes then
      cmd = string.format("edit %s", entry.notes[1])
    else
      local choice = vim.fn.confirm(
        string.format("The entry '%s' has no notes.\nCreate a new one?", entry.ref),
        "&Yes\n&No",
        2
      )

      if choice == 1 then
        local config = require("papis.config")
        local notes_name = db.config:get_conf_value("notes_name")

        local new_note_cmd = vim.list_extend(vim.deepcopy(config.papis_cmd_base),
          { "update", "--set", "notes", notes_name, "papis_id:" .. papis_id })
        local result = vim.system(new_note_cmd, { text = true }):wait()
        if result.code ~= 0 then
          vim.notify(
            string.format("Failed to create new note for entry with papis_id: '%s': %s", papis_id,
              result.stderr or "unknown error"),
            vim.log.levels.ERROR)
          return
        end

        local entry_has_note = uv.new_timer()
        assert(entry_has_note, "Failed to create libuv timer")
        local max_retries = 20
        local retry_count = 0

        local function check_for_notes()
          entry = db.data:get({ papis_id = papis_id })[1]

          if not entry or not entry.notes then
            retry_count = retry_count + 1
            if retry_count >= max_retries then
              log.warn("Maximum retries reached waiting for notes file to be indexed")
              entry_has_note:close()
              return
            end
            entry_has_note:start(5, 0, vim.schedule_wrap(check_for_notes))
            return
          end

          entry_has_note:close()
          local formatter_enabled = vim.tbl_contains(config.enabled_modules, "formatter")
          if formatter_enabled then
            require("papis.formatter").format_entire_file(entry)
          end
          log.debug("Opening newly created notes file")
          self:do_open_text_file(papis_id, type)
        end

        entry_has_note:start(0, 0, vim.schedule_wrap(check_for_notes))
      else
      end
    end
  elseif type == "info" then
    log.debug("Opening an info file")
    cmd = string.format("edit %s", info_path)
  end
  vim.cmd(cmd)
end

---Makes nui lines ready to be displayed
---@param lines_format_tbl FormatEntryTable A format table defining multiple lines
---@param entry PapisEntry|PapisAskEntry An entry
---@return NuiLine[] nui_lines A list of nui lines
---@return integer max_width The maximum character length of the nui lines
function M:make_nui_lines(lines_format_tbl, entry)
  local lines = {}
  local line_widths = {}
  local max_width = 0
  -- local max_width_line_nr
  local vspace = {}
  for _, line_format_tbl in ipairs(lines_format_tbl) do
    local line = {}
    local width = 0
    if line_format_tbl[1] == "empty_line" then
      -- here we add a line without hl group
      line[#line + 1] = { " " }
    else
      -- we format the strings for the line and add them to the line
      local display_strings = self:format_display_strings(entry, line_format_tbl)
      for k, v in ipairs(display_strings) do
        line[#line + 1] = { v[1], v[2] }
        if v[1] == "vspace" then
          -- in case of vspace elements, we gotta keep track where they occur
          vspace[#vspace + 1] = { linenr = #lines + 1, elem = k }
        else
          -- we get the width of the line by adding all elements' width
          width = width + vim.fn.strdisplaywidth(v[1], 1)
        end
      end
    end
    if not vim.tbl_isempty(line) then
      -- add the width of the line just processed to the table of line_widths
      line_widths[#lines + 1] = width

      -- add the line just processed to the table of lines
      lines[#lines + 1] = line
    end
  end

  max_width = math.max(unpack(line_widths))

  local vspace_len = 0
  -- sort out vertical space padding for each line that has `vspace`
  for _, v in pairs(vspace) do
    if line_widths[v.linenr] >= max_width then
      -- if the line with the vspace is the longest line, only add 1 space
      vspace_len = 1
    else
      -- if it isn't the longest line, calculate required vspace
      vspace_len = max_width - (line_widths[v.linenr])
    end
    -- replace "vspace" by the required number of " "
    lines[v.linenr][v.elem] = { string.rep(" ", vspace_len) }
    -- and recalculate max_width
    max_width = math.max(max_width, (line_widths[v.linenr] + vspace_len))
  end

  -- turn our lines into NuiLines
  local nui_lines = {}
  for _, line in ipairs(lines) do
    local nui_line = NuiLine()
    for _, v in ipairs(line) do
      nui_line:append(v[1], v[2])
    end
    nui_lines[#nui_lines + 1] = nui_line
  end
  return nui_lines, max_width
end

---Determine whether there's a process with a given pid
---@param pid? integer pid of the process
---@return boolean pid_exists True if process exists, false otherwise
function M.does_pid_exist(pid)
  local pid_exists = false
  pid = tonumber(pid)
  if not pid then
    return false
  end

  local ok, _, name = uv.kill(pid, 0)
  if ok or (name == "EPERM") then
    pid_exists = true
  end

  return pid_exists
end

---A list of { formatted_text, highlight_group }
---@alias PapisDisplayStrings
---| table<string, string>[]

---Creates a table of formatted strings to be displayed in a line (e.g. Telescope results pane)
---@param entry PapisEntry|PapisAskEntry A papis entry
---@param line_format_tbl FormatEntryTable A table containing format strings defining the line
---@param use_shorttitle? boolean If true, use short titles
---@param remove_editor_if_author? boolean If true, remove editor if author exists
---@return PapisDisplayStrings display_strings A list of display strings
function M:format_display_strings(entry, line_format_tbl, use_shorttitle, remove_editor_if_author)
  local enable_icons = require("papis.config").enable_icons

  -- if the line has just one item, embed within a tbl so we can process like the others
  if type(line_format_tbl[1]) == "string" then
    log.debug("line has just one item, embed within table")
    line_format_tbl = { line_format_tbl }
  end

  ---Table containing tables {format string, string, highlight group}
  ---@type table<table<string, string, string>>
  local formatting_items = {}

  -- iterate over each string element in the line_format_tbl
  for _, line_item in ipairs(line_format_tbl) do
    local line_item_copy = vim.deepcopy(line_item)

    -- format values
    local processed_string = nil
    if line_item_copy[1] == "author" and (entry.author or entry.author_list or entry.editor) then -- add author
      local authors = {}
      if entry.author_list then
        for _, vv in ipairs(entry.author_list) do
          authors[#authors + 1] = vv.family
        end
        processed_string = table.concat(authors, ", ")
      elseif entry.author then
        if string.find(entry.author, " and ") then
          local str = string.gsub(entry.author, " and ", "|")
          local str_split = self.do_split_str(str, "|")
          for _, s in ipairs(str_split) do
            authors[#authors + 1] = self.do_split_str(s, ",")[1]
          end
        else
          authors[#authors + 1] = self.do_split_str(entry.author, ",")[1]
        end
        processed_string = table.concat(authors, ", ")
      elseif entry.editor then
        if string.find(entry.editor, " and ") then
          local str = string.gsub(entry.editor, " and ", "|")
          local str_split = self.do_split_str(str, "|")
          for _, s in ipairs(str_split) do
            authors[#authors + 1] = self.do_split_str(s, ",")[1]
          end
        else
          authors[#authors + 1] = self.do_split_str(entry.editor, ",")[1]
        end
        processed_string = table.concat(authors, ", ") .. " (eds.)"
      end
    elseif line_item_copy[1] == "editor" and entry.editor then
      if not remove_editor_if_author then
        local editors = {}
        if string.find(entry.editor, " and ") then
          local str = string.gsub(entry.editor, " and ", "|")
          local str_split = self.do_split_str(str, "|")
          for _, s in ipairs(str_split) do
            editors[#editors + 1] = self.do_split_str(s, ",")[1]
          end
        else
          editors[#editors + 1] = self.do_split_str(entry.editor, ",")[1]
        end
        processed_string = table.concat(editors, ", ")
      end
    elseif line_item_copy[1] == "title" and (entry.title or entry.shorttitle) then
      if use_shorttitle then
        local shorttitle = entry.shorttitle or entry.title:match("([^:]+)")
        processed_string = shorttitle
      else
        processed_string = entry.title
      end
    elseif line_item_copy[1] == "files" and (
          (type(entry.files) == "table" and not vim.tbl_isempty(entry.files)) or
          (type(entry.related_to) == "table" and not vim.tbl_isempty(entry.related_to))
        ) then
      if type(entry.files) == "table" and not vim.tbl_isempty(entry.files) then
        processed_string = table.concat(self.get_filenames(entry.files), ", ")
      elseif type(entry.related_to) == "table" and not vim.tbl_isempty(entry.related_to) then
        processed_string = "related_to"
      end
    elseif line_item_copy[1] == "notes" and (type(entry.notes) == "table" and not vim.tbl_isempty(entry.notes)) then
      processed_string = self.get_filenames(entry.notes)
    elseif line_item_copy[1] == "related_to" and (type(entry.related_to) == "table" and not vim.tbl_isempty(entry.related_to)) then
      processed_string = make_related_to_string(entry)
    elseif entry[line_item_copy[1]] then -- add other elements if they exist in the entry
      local input = entry[line_item_copy[1]]
      if type(input) == "table" then
        -- if it's a table, convert to string
        processed_string = table.concat(entry[line_item_copy[1]], ", ")
      else
        processed_string = input
      end
    elseif line_item_copy[4] == "force_space" then
      -- set icon to empty space
      line_item_copy[2] = "  " -- NOTE: this only works for icons, hardcoded because luajit doesn't support utf8.len
      -- add dummy element
      processed_string = "dummy"
    elseif line_item_copy[1] == "vspace" then
      processed_string = "vspace"
    end

    -- set icons or normal chars as desired
    local icon_keys = { 2, 5 }
    for _, icon_key in ipairs(icon_keys) do
      if type(line_item_copy[icon_key]) == "table" then
        -- map of strings to {icon, non-icon}
        local icon_map = line_item_copy[icon_key]
        -- {icon, non-icon} for the given string
        local icon_entry = icon_map[processed_string]
        if icon_entry then
          if enable_icons then
            line_item_copy[icon_key] = icon_entry[1]
          else
            line_item_copy[icon_key] = icon_entry[2]
          end
        else
          if enable_icons then
            line_item_copy[icon_key] = icon_map.fallback[1]
          else
            line_item_copy[icon_key] = icon_map.fallback[2]
          end
        end
      end
    end

    -- if a string exists, add keys if required and add hl group etc
    if processed_string then
      if line_item_copy[4] == "show_key" then
        formatting_items[#formatting_items + 1] = { line_item_copy[5], line_item_copy[1], line_item_copy[6] }
      end
      formatting_items[#formatting_items + 1] = { line_item_copy[2], processed_string, line_item_copy[3] }
    end
  end

  ---Table containing tables {formatted string, highlight group}
  local display_strings = {}
  for _, formatting_item in ipairs(formatting_items) do
    local formatted_str = string.format(formatting_item[1], formatting_item[2])
    display_strings[#display_strings + 1] = { formatted_str, formatting_item[3] }
  end

  return display_strings
end

return M
