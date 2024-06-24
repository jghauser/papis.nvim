--
-- PAPIS | UTILS
--
--
-- Various utility functions used throughout the plugin.
--

local NuiLine = require("nui.line")
local NuiPopup = require("nui.popup")
local nuiEvent = require("nui.utils.autocmd").event
local Path = require("pathlib")

local new_timer = vim.loop.new_timer
local os_name = vim.loop.os_uname()

local log = require("papis.log")

local is_windows
local is_macos
local is_linux
if os_name.sysname == "Linux" then
  is_linux = true
elseif os_name.sysname == "Darwin" then
  is_macos = true
elseif os_name.version:match("Windows") then
  is_windows = true
end

local M = {}

---Get the cite_format for the current filetype
---@param filetype string #Filetype for which we need a cite_format
---@return string|table #cite_format to be used for the filetype. If table, then first is for inserting, second for parsing
function M.get_cite_format(filetype)
  local config = require("papis.config")
  local cite_formats = config["cite_formats"]
  local cite_formats_fallback = config["cite_formats_fallback"]

  if config["always_use_plain"] then
    local cite_format = cite_formats["plain"] or "%s"
    return cite_format
  else
    local cite_format = cite_formats[filetype] or cite_formats[cite_formats_fallback]
    return cite_format
  end
end

---Splits string by `inputstr` and trims whitespace
---@param inputstr string #String to be split
---@param sep? string #String giving each character by which to split
---@return table #List of split elements
function M.do_split_str(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    str = str:match("^()%s*$") and "" or str:match("^%s*(.*%S)")
    t[#t + 1] = str
  end
  return t
end

-- Open file outside neovim
---@param path string #Path to the file
function M:do_open_file_external(path)
  local opentool = require("papis.sqlite-wrapper").config:get_value({ id = 1 }, "opentool")
  local opentool_table = self.do_split_str(opentool, " ")
  local command = table.remove(opentool_table, 1)
  local args = opentool_table
  args[#args + 1] = path

  local handle
  handle = vim.loop.spawn(command, {
    args = args,
    stdio = { nil, nil, nil }
  }, vim.schedule_wrap(function()
    if handle then
      handle:close()
    end
  end))
end

---Gets the file names given a list of full paths
---@param full_paths table|nil #A list of paths or nil
---@return table #A list of file names
function M.get_filenames(full_paths)
  local filenames = {}
  if full_paths then
    for _, full_path in ipairs(full_paths) do
      local filename = Path(full_path):basename()
      filenames[#filenames + 1] = filename
    end
  end
  return filenames
end

---Open an entry's attached files
---@param papis_id string #The `papis_id` of the entry
function M:do_open_attached_files(papis_id)
  local db = require("papis.sqlite-wrapper")
  if not db then
    return nil
  end
  local entry = db.data:get({ papis_id = papis_id }, { "files", "id" })[1]
  local filenames = self.get_filenames(entry["files"])
  local lookup_tbl = {}
  for k, filename in ipairs(filenames) do
    lookup_tbl[filename] = entry["files"][k]
  end
  if vim.tbl_isempty(filenames) then
    log.info("This item has no attached files.")
  elseif #filenames == 1 then
    log.info("Opening file '" .. filenames[1] .. "' ")
    local path = lookup_tbl[filenames[1]]
    self:do_open_file_external(path)
  else
    vim.ui.select(filenames, {
      prompt = "Select attachment to open:",
    }, function(choice)
      if choice then
        log.info("Opening file '" .. choice .. "' ")
        local path = lookup_tbl[choice]
        self:do_open_file_external(path)
      end
    end)
  end
end

---Opens a text file with neovim, asking to select one if there are multiple buf_options
---@param papis_id string #The `papis_id` of the entry
---@param type string #Either "note" or "info", specifying the type of file
function M:do_open_text_file(papis_id, type)
  local db = require("papis.sqlite-wrapper")
  if not db then
    log.warn("Sqlite-wrapper has not been initialised properly. Aborting...")
    return nil
  end
  log.debug("Opening a text file")
  local entry = db.data:get({ papis_id = papis_id }, { "notes", "id" })[1]
  local info_path = Path(db.metadata:get_value({ entry = entry["id"] }, "path"))
  log.debug("Text file in folder: " .. tostring(info_path))
  local cmd = ""
  if type == "note" then
    log.debug("Opening a note")
    if entry["notes"] then
      cmd = string.format("edit %s", entry["notes"][1])
    else
      local lines_text = {
        { "This entry has no notes.", "WarningMsg" },
        { "Create a new one? (Y/n)" },
      }
      local width = 0
      for _, line in pairs(lines_text) do
        width = math.max(width, #line[1])
      end
      local popup = NuiPopup({
        enter = true,
        position = "50%",
        size = {
          width = width,
          height = #lines_text,
        },
        border = {
          padding = { 1, 1, 1, 1 },
          style = "single",
        },
        buf_options = {
          modifiable = false,
          readonly = true,
        },
      })

      popup:map("n", { "Y", "y", "<cr>" }, function(_)
        popup:unmount()
        local config = require("papis.config")
        local create_new_note_fn = config["create_new_note_fn"]
        local notes_name = db.config:get_value({ id = 1 }, "notes_name")
        local enable_modules = config["enable_modules"]
        create_new_note_fn(papis_id, notes_name)
        if enable_modules["formatter"] then
          entry = db.data:get({ papis_id = papis_id })[1]
          local pattern = [[*]] .. notes_name:match("^.+(%..+)$")
          log.debug("Formatter autocmd pattern: " .. vim.inspect(pattern))
          local callback = config["formatter"]["format_notes_fn"]
          require("papis.formatter").create_autocmd(pattern, callback, entry)
        end
        local entry_has_note = new_timer()
        local file_opened = false
        entry_has_note:start(
          0,
          5,
          vim.schedule_wrap(function()
            entry = db.data:get({ papis_id = papis_id }, { "notes" })[1]
            if entry["notes"] and not file_opened then
              log.debug("Opening newly created notes file")
              self:do_open_text_file(papis_id, type)
              file_opened = true
              entry_has_note:stop()
              entry_has_note:close()
            end
          end)
        )
      end, { noremap = true, nowait = true })
      popup:map("n", { "N", "n", "<esc>", "q" }, function(_)
        popup:unmount()
      end, { noremap = true, nowait = true })

      popup:on({ nuiEvent.BufLeave }, function()
        popup:unmount()
      end, { once = true })

      for k, line in pairs(lines_text) do
        local nuiline = NuiLine()
        nuiline:append(unpack(line))
        nuiline:render(popup.bufnr, -1, k)
      end

      popup:mount()
    end
  elseif type == "info" then
    log.debug("Opening an info file")
    cmd = string.format("edit %s", info_path)
  end
  vim.cmd(cmd)
end

---Takes the format table and removes k = v pairs not existing in the entry + some other conditions
---@param format_table table #As defined in config.lua (e.g. "preview_format")
---@param entry table #An entry
---@param remove_editor_if_author boolean? #If true we don't add the editor if the entry has an author
---@return table #Same format as `format_table` but with k = v pairs removed
function M.do_clean_format_tbl(format_table, entry, remove_editor_if_author)
  local enable_icons = require("papis.config")["enable_icons"]
  local clean_format_table = {}
  for _, v in ipairs(format_table) do
    local f = vim.deepcopy(v) -- TODO: check if deepcopy necessary
    -- add entry value if either there's an entry value corresponding to the value in the
    -- format table or the value in the format table is "empty_line"
    if entry[f[1]] or f[1] == "empty_line" then
      clean_format_table[#clean_format_table + 1] = f
      -- don't add editor if there is author and use_author_if_editor is true
    elseif remove_editor_if_author and f[1] == "author" and entry["editor"] then
      clean_format_table[#clean_format_table + 1] = f
      -- add empty space if space is forced but the element doesn't exist for entry
    elseif f[4] == "force_space" then
      f[2] = "  " -- TODO: this only works for icons, hardcoded because luajit doesn't support utf8.len
      clean_format_table[#clean_format_table + 1] = f
    end
    -- use either icons or normal characters depending on settings
    if type(f[2]) == "table" then
      if enable_icons then
        f[2] = f[2][1]
      else
        f[2] = f[2][2]
      end
    end
    if type(f[5]) == "table" then
      if enable_icons then
        f[5] = f[5][1]
      else
        f[5] = f[5][2]
      end
    end
  end
  return clean_format_table
end

---Makes nui lines ready to be displayed
---@param clean_format_tbl table #A cleaned format table as output by self.do_clean_format_tbl
---@param entry table #An entry
---@return table #A list of nui lines
---@return integer #The maximum character length of the nui lines
function M.make_nui_lines(clean_format_tbl, entry)
  local nui_lines = {}
  local max_width = 0
  for _, v in ipairs(clean_format_tbl) do
    local line = NuiLine()
    local width1 = 0
    local width2 = 0
    if v[1] == "empty_line" then
      line:append(" ")
    else
      if v[4] == "show_key" then
        local str = v[1]
        str = string.format(v[5], str)
        str = string.gsub(str, "\n", "")
        width1 = vim.fn.strdisplaywidth(str, 1)
        line:append(str, v[6])
      end
      if type(entry[v[1]]) ~= "table" then
        local str = tostring(entry[v[1]])
        str = string.format(v[2], str)
        str = string.gsub(str, "\n", "")
        width2 = vim.fn.strdisplaywidth(str, 1)
        line:append(str, v[3])
      else
        local str = table.concat(entry[v[1]], ", ")
        str = string.format(v[2], str)
        str = string.gsub(str, "\n", "")
        width2 = vim.fn.strdisplaywidth(str, 1)
        line:append(str, v[3])
      end
    end
    max_width = math.max(max_width, (width1 + width2))
    nui_lines[#nui_lines + 1] = line
  end

  return nui_lines, max_width
end

---Get the list of keys required by format table
---@param tbls table #A format table(e.g. "preview_format" in config.lua)
---@return table #A list of keys
function M:get_required_db_keys(tbls)
  local required_db_keys = { id = true }
  for _, tbl in ipairs(tbls) do
    for _, v in ipairs(tbl) do
      if v[1] == nil then
        required_db_keys[v] = true
      else
        required_db_keys[v[1]] = true
      end
    end
  end
  required_db_keys["empty_line"] = nil
  required_db_keys = vim.tbl_keys(required_db_keys)
  return required_db_keys
end

---Determine whether there's a process with a given pid
---@param pid? number #pid of the process
---@return boolean #True if process exists, false otherwise
function M.does_pid_exist(pid)
  local output
  local cmd
  local pid_exists = false
  if pid then
    if is_linux or is_macos then
      cmd = "ps -p " .. pid
    elseif is_windows then
      cmd = 'tasklist /FI "PID eq ' .. pid .. '"'
    end
    local file = io.popen(cmd)
    if file then
      output = file:read("*all")
      file:close()
    end
    local pid_found = string.find(output, tostring(pid), 1, true)
    if pid_found then
      pid_exists = true
    end
  end
  return pid_exists
end

---Creates a table of formatted strings to be displayed in a line (e.g. Telescope results pane)
---@param entry table #A papis entry
---@param use_shortitle? boolean #If true, use short titles
---@return table #A list of strings
function M:format_display_strings(entry, format_table, use_shortitle)
  local clean_results_format = self.do_clean_format_tbl(format_table, entry, true)

  local str_elements = {}
  for _, v in ipairs(clean_results_format) do
    assert(v ~= "empty_line", "Empty lines aren't allowed for the results_format")
    if v[1] == "author" then
      local authors = {}
      if entry["author_list"] then
        for _, vv in ipairs(entry["author_list"]) do
          authors[#authors + 1] = vv["family"]
        end
        str_elements[#str_elements + 1] = table.concat(authors, ", ")
      elseif entry["author"] then
        if string.find(entry["author"], " and ") then
          local str = string.gsub(entry["author"], " and ", "|")
          local str_split = self.do_split_str(str, "|")
          for _, s in ipairs(str_split) do
            authors[#authors + 1] = self.do_split_str(s, ",")[1]
          end
        else
          authors[#authors + 1] = self.do_split_str(entry["author"], ",")[1]
        end
        str_elements[#str_elements + 1] = table.concat(authors, ", ")
      elseif entry["editor"] then
        if string.find(entry["editor"], " and ") then
          local str = string.gsub(entry["editor"], " and ", "|")
          local str_split = self.do_split_str(str, "|")
          for _, s in ipairs(str_split) do
            authors[#authors + 1] = self.do_split_str(s, ",")[1]
          end
        else
          authors[#authors + 1] = self.do_split_str(entry["editor"], ",")[1]
        end
        str_elements[#str_elements + 1] = table.concat(authors, ", ") .. " (eds.)"
      end
    elseif v[1] == "title" and use_shortitle then
      local shortitle = entry["title"]:match("([^:]+)")
      str_elements[#str_elements + 1] = shortitle
    else
      if entry[v[1]] then
        str_elements[#str_elements + 1] = entry[v[1]]
      elseif v[4] == "force_space" then
        str_elements[#str_elements + 1] = "dummy"
      end
    end
  end

  local display_strings = {}
  for k, str_element in ipairs(str_elements) do
    local formatted_str = string.format(clean_results_format[k][2], str_element)
    display_strings[#display_strings + 1] = { formatted_str, clean_results_format[k][3] }
  end

  return display_strings
end

return M
