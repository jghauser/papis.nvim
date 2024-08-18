--
-- PAPIS | UTILS
--
--
-- Various utility functions used throughout the plugin.
--

local NuiLine = require("nui.line")
local NuiPopup = require("nui.popup")
local Path = require("pathlib")

local new_timer = vim.uv.new_timer
local os_name = vim.uv.os_uname()

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
  local opentool = require("papis.sqlite-wrapper").config:get_conf_value("opentool")
  local opentool_table = self.do_split_str(opentool, " ")
  local command = table.remove(opentool_table, 1)
  local args = opentool_table
  args[#args + 1] = path

  local handle
  handle = vim.uv.spawn(command, {
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
  local filenames = self.get_filenames(entry.files)
  local lookup_tbl = {}
  for k, filename in ipairs(filenames) do
    lookup_tbl[filename] = entry.files[k]
  end
  if vim.tbl_isempty(filenames) then
    vim.notify("This item has no attached files.", vim.log.levels.WARN)
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

local popup
local file_queue = {}

-- Function to be called when a popup is closed
function M:on_popup_close()
  -- If there are no more active popups, open the files in the queue
  if (not popup) and (#file_queue > 0) then
    self:do_open_text_file(unpack(file_queue[1]))
    table.remove(file_queue, 1)
  end
end

---Opens a text file with neovim, asking to select one if there are multiple buf_options
---@param papis_id string #The `papis_id` of the entry
---@param type string #Either "note" or "info", specifying the type of file
function M:do_open_text_file(papis_id, type)
  local db = require("papis.sqlite-wrapper")
  if not db then
    log.error("Sqlite-wrapper has not been initialised properly. Aborting...")
    return nil
  end
  log.debug("Opening a text file")
  local entry = db.data:get({ papis_id = papis_id }, { "notes", "id" })[1]
  local info_path = Path(db.metadata:get_value({ entry = entry.id }, "path"))
  log.debug("Text file in folder: " .. tostring(info_path))
  local cmd = ""
  if type == "note" then
    log.debug("Opening a note")
    if entry.notes then
      cmd = string.format("edit %s", entry.notes[1])
      popup = nil
      self:on_popup_close()
    else
      local lines_text = {
        { "This entry has no notes.", "WarningMsg" },
        { "Create a new one? (Y/n)" },
      }
      local width = 0
      for _, line in pairs(lines_text) do
        width = math.max(width, #line[1])
      end

      -- If there are active popups, add the file to the queue and return
      if popup then
        table.insert(file_queue, { papis_id, type })
        return
      end

      popup = NuiPopup({
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
        local create_new_note_fn = config.create_new_note_fn
        local notes_name = db.config:get_conf_value("notes_name")
        create_new_note_fn(papis_id, notes_name)
        local entry_has_note = new_timer()
        local file_opened = false
        entry_has_note:start(
          0,
          5,
          vim.schedule_wrap(function()
            entry = db.data:get({ papis_id = papis_id })[1]
            if entry.notes and not file_opened then
              local enable_modules = config.enable_modules
              if enable_modules["formatter"] then
                require("papis.formatter").format_entire_file(entry)
              end
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
        popup = nil
        self:on_popup_close()
      end, { noremap = true, nowait = true })

      for k, line in pairs(lines_text) do
        local nuiline = NuiLine()
        nuiline:append(unpack(line))
        nuiline:render(popup.bufnr, -1, k)
      end

      vim.schedule(function()
        popup:mount()
      end)
    end
  elseif type == "info" then
    log.debug("Opening an info file")
    cmd = string.format("edit %s", info_path)
  end
  vim.cmd(cmd)
end

---Makes nui lines ready to be displayed
---@param lines_format_tbl table #A format table defining multiple lines
---@param entry table #An entry
---@return table #A list of nui lines
---@return integer #The maximum character length of the nui lines
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
      local formatted_strings = self:format_display_strings(entry, line_format_tbl)
      for k, v in ipairs(formatted_strings) do
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
    -- add the width of the line just processed to the table of line_widths
    line_widths[#lines + 1] = width

    -- add the line just processed to the table of lines
    lines[#lines + 1] = line
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
---@param line_format_tbl table #A table containing format strings defining the line
---@param use_shortitle? boolean #If true, use short titles
---@param remove_editor_if_author? boolean #If true, remove editor if author exists
---@return table #A list of lists like { { "formatted string", "HighlightGroup", {opts} }, ... }
function M:format_display_strings(entry, line_format_tbl, use_shortitle, remove_editor_if_author)
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

    -- set icons or normal chars as desired
    local icon_keys = { 2, 5 }
    for _, icon_key in ipairs(icon_keys) do
      if type(line_item_copy[icon_key]) == "table" then
        if enable_icons then
          line_item_copy[icon_key] = line_item_copy[icon_key][1]
        else
          line_item_copy[icon_key] = line_item_copy[icon_key][2]
        end
      end
    end

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
    elseif line_item_copy[1] == "title" and (entry.title or entry.shortitle) then
      if use_shortitle then
        local shortitle = entry.shortitle or entry.title:match("([^:]+)")
        processed_string = shortitle
      else
        processed_string = entry.title
      end
    elseif entry[line_item_copy[1]] then -- add other elements if they exist in the entry
      local input = entry[line_item_copy[1]]
      if line_item_copy[1] == ("notes" or "files") then
        -- get only file names (not full path)
        input = self.get_filenames(entry[line_item_copy[1]])
      end
      if type(input) == "table" then
        -- if it's a table, convert to string
        processed_string = table.concat(entry[line_item_copy[1]], ", ")
      else
        processed_string = input
      end
    elseif line_item_copy[4] == "force_space" then
      -- set icon to empty space
      line_item_copy[2] = "  " -- TODO: this only works for icons, hardcoded because luajit doesn't support utf8.len
      -- add dummy element
      processed_string = "dummy"
    elseif line_item_copy[1] == "vspace" then
      processed_string = "vspace"
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
  ---@type table<table<string, string>>
  local formatted_str_and_hl = {}
  for _, formatting_item in ipairs(formatting_items) do
    local formatted_str = string.format(formatting_item[1], formatting_item[2])
    formatted_str_and_hl[#formatted_str_and_hl + 1] = { formatted_str, formatting_item[3] }
  end

  return formatted_str_and_hl
end

return M
