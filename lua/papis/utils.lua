--
-- PAPIS | UTILS
--
--
-- Various utility functions used throughout the plugin.
--

local NuiLine = require("nui.line")
local NuiPopup = require("nui.popup")
local nuiEvent = require("nui.utils.autocmd").event
local Path = require("plenary.path")
local strdisplaywidth = require("plenary.strings").strdisplaywidth
local job = require("plenary.job")

local new_timer = vim.loop.new_timer
local os_name = vim.loop.os_uname().sysname

local log = require("papis.logger")

local is_windows = os_name == "Windows"
local is_macos = os_name == "Darwin"
local is_linux = os_name == "Linux"

local M = {}

---Get the cite_format for the current filetype
---@param filetype string #Filetype for which we need a cite_format
---@return string #cite_format to be used for the filetype
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
---@param sep? string #String giving each character by witch to split
---@return table #List of split elements
function M.do_split_str(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
    str = str:match("^()%s*$") and "" or str:match("^%s*(.*%S)")
    table.insert(t, str)
  end
  return t
end

-- Open file outside neovim
---@param path string #Path to the file
function M.do_open_file_external(path)
  -- local safe_path = vim.fn.shellescape(path)
  local o = {}
  if is_windows then
    o.command = "rundll32.exe"
    o.args = { "url.dll,FileProtocolHandler", path }
  else
    if is_linux then
      o.command = "xdg-open"
    elseif is_macos then
      o.command = "open"
    end
    o.args = { path }
  end

  job:new(o):start()
end

---Gets the file names given a list of full paths
---@param full_paths table|nil #A list of paths or nil
---@return table #A list of file names
function M.get_filenames(full_paths)
  local filenames = {}
  if full_paths then
    for _, full_path in ipairs(full_paths) do
      local filename = Path:new(full_path):_split()
      filename = filename[#filename]
      table.insert(filenames, filename)
    end
  end
  return filenames
end

---Open an entry's attached files
---@param ref string #The `ref` of the entry
function M:do_open_attached_files(ref)
  local db = require("papis.sqlite-wrapper")
  if not db then
    return nil
  end
  local entry = db.data:get({ ref = ref }, { "files", "id" })[1]
  local filenames = self.get_filenames(entry["files"])
  local lookup_tbl = {}
  for k, filename in ipairs(filenames) do
    lookup_tbl[filename] = entry["files"][k]
  end
  if vim.tbl_isempty(filenames) then
    log.debug("This item has no attached files.")
  elseif #filenames == 1 then
    log.info("Opening file '" .. filenames[1] .. "' ")
    local path = lookup_tbl[filenames[1]]
    self.do_open_file_external(path)
  else
    vim.ui.select(filenames, {
      prompt = "Select attachment to open:",
    }, function(choice)
      if choice then
        log.info("Opening file '" .. choice .. "' ")
        local path = lookup_tbl[choice]
        self.do_open_file_external(path)
      end
    end)
  end
end

---Opens a text file with neovim, asking to select one if there are multiple buf_options
---@param ref string #The `ref` of the entry
---@param type string #Either "note" or "info", specifying the type of file
function M:do_open_text_file(ref, type)
  local db = require("papis.sqlite-wrapper")
  if not db then
    log.warn("Sqlite-wrapper has not been initialised properly. Aborting...")
    return nil
  end
  log.debug("Opening a text file")
  local entry = db.data:get({ ref = ref }, { "notes", "id" })[1]
  local info_path = Path:new(db.metadata:get_value({ entry = entry["id"] }, "path"))
  log.debug("Text file in folder: " .. info_path:absolute())
  local cmd = ""
  if type == "note" then
    log.debug("Opening a note")
    if entry["notes"] then
      cmd = string.format("edit %s", entry["notes"][1])
    else
      local popup = NuiPopup({
        enter = true,
        position = "50%",
        size = {
          width = 24,
          height = 2,
        },
        border = {
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
        local notes_name = config["papis_python"]["notes_name"]
        local enable_modules = config["enable_modules"]
        create_new_note_fn(ref, notes_name)
        if enable_modules["formatter"] then
          entry = db.data:get({ ref = ref })[1]
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
            entry = db.data:get({ ref = ref }, { "notes" })[1]
            if entry["notes"] and not file_opened then
              log.debug("Opening newly created notes file")
              self:do_open_text_file(ref, type)
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

      local line1 = NuiLine()
      line1:append("This entry has no notes.", "WarningMsg")
      line1:render(popup.bufnr, -1, 1)
      local line2 = NuiLine()
      line2:append("Create a new one? (Y/n)")
      line2:render(popup.bufnr, -1, 2)

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
  local clean_format_table = {}
  for _, v in ipairs(format_table) do
    -- add entry value if either there's an entry value corresponding to the value in the
    -- format table or the value in the format table is "empty_line"
    if entry[v[1]] or v[1] == "empty_line" then
      table.insert(clean_format_table, v)
    -- don't add editor if there is author and use_author_if_editor is true
    elseif remove_editor_if_author and v[1] == "author" and entry["editor"] then
      table.insert(clean_format_table, v)
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
        width1 = strdisplaywidth(str, 1)
        line:append(str, v[6])
      end
      if type(entry[v[1]]) ~= "table" then
        local str = tostring(entry[v[1]])
        str = string.format(v[2], str)
        str = string.gsub(str, "\n", "")
        width2 = strdisplaywidth(str, 1)
        line:append(str, v[3])
      else
        local str = table.concat(entry[v[1]], ", ")
        str = string.format(v[2], str)
        str = string.gsub(str, "\n", "")
        width2 = strdisplaywidth(str, 1)
        line:append(str, v[3])
      end
    end
    max_width = math.max(max_width, (width1 + width2))
    table.insert(nui_lines, line)
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
      cmd = "ps -q " .. pid
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
---@return table #A list of strings
function M:format_display_strings(entry, format_table)
  local clean_results_format = self.do_clean_format_tbl(format_table, entry, true)

  local str_elements = {}
  for _, v in ipairs(clean_results_format) do
    assert(v ~= "empty_line", "Empty lines aren't allowed for the results_format")
    if v[1] == "author" then
      local authors = {}
      if entry["author_list"] then
        for _, vv in ipairs(entry["author_list"]) do
          table.insert(authors, vv["family"])
        end
        table.insert(str_elements, table.concat(authors, ", "))
      elseif entry["author"] then
        if string.find(entry["author"], " and ") then
          local str = string.gsub(entry["author"], " and ", "|")
          local str_split = self.do_split_str(str, "|")
          for _, s in ipairs(str_split) do
            table.insert(authors, self.do_split_str(s, ",")[1])
          end
        else
          table.insert(authors, self.do_split_str(entry["author"], ",")[1])
        end
        table.insert(str_elements, table.concat(authors, ", "))
      elseif entry["editor"] then
        if string.find(entry["editor"], " and ") then
          local str = string.gsub(entry["editor"], " and ", "|")
          local str_split = self.do_split_str(str, "|")
          for _, s in ipairs(str_split) do
            table.insert(authors, self.do_split_str(s, ",")[1])
          end
        else
          table.insert(authors, self.do_split_str(entry["editor"], ",")[1])
        end
        table.insert(str_elements, table.concat(authors, ", ") .. " (eds.)")
      end
    else
      table.insert(str_elements, entry[v[1]])
    end
  end

  local display_strings = {}
  for k, str_element in ipairs(str_elements) do
    local formatted_str = string.format(clean_results_format[k][2], str_element)
    table.insert(display_strings, { formatted_str, clean_results_format[k][3] })
  end

  return display_strings
end

return M
