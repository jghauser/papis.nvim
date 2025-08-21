--
-- PAPIS | ASK | PICKER_COMMON
--
--
-- Common functions for all pickers
--

local fs = vim.fs

local markdown = require("papis.ask.markdown")
local utils = require("papis.utils")
local config = require("papis.config")
local log = require("papis.log")

---Delete an entry file
---@param filepath string The filepath to be deleted
---@return boolean #Whether deletion was successful
local function delete_entry_file(filepath)
  local ok, err = os.remove(filepath)
  if not ok then
    vim.notify("Failed to delete ask entry: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  return true
end


---Get directory where ask JSON files are stored
---@return string dir The storage directory path
local function get_storage_dir()
  local dir = fs.joinpath(vim.fn.stdpath("data"), "papis", "ask")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  return dir
end

---Save the raw JSON string output from papis ask.
---@param json_str string Raw JSON output from papis ask
---@param slash string The slash command used
---@return string|nil path The path where the file was saved, or nil on error
local function save_result(json_str, slash)
  local ts = os.date("%Y%m%d-%H%M%S")
  local safe_slash = tostring(slash or ""):gsub("[^%w_-]", "_")
  local filename = string.format("%s-%s.json", ts, safe_slash)
  local path = fs.joinpath(get_storage_dir(), filename)
  local f, err = io.open(path, "w")
  if not f then
    vim.notify("Failed to save ask result: " .. tostring(err), vim.log.levels.ERROR)
    return nil
  end
  f:write(json_str or "")
  f:close()
  return path
end

---Parse timestamp and slash from filename
---@param filename string The filename
---@return string time_added Human-readable timestamp
---@return string slash Slash command
local function parse_meta_from_filename(filename)
  local y, m, d, H, Min, S, slash = filename:match("^(%d%d%d%d)(%d%d)(%d%d)-(%d%d)(%d%d)(%d%d)%-(.+)%.json$")
  local time_added = string.format("%s-%s-%s %s:%s:%s", y, m, d, H, Min, S)
  return time_added, slash
end

---@type table Text to display when no questions have been asked yet
local placeholder_lines = {
  "Welcome to Papis-ask! You can:",
  "",
  "1. Type `/ask <your question>` in the search box to ask a new question",
  "2. Press Enter to submit your question",
  "3. Your questions and answers will appear here once Papis-ask finishes",
  "",
  "Example: `/ask What is the meaning of life?`",
}


local M = {}

---Creates a string that is used to search among entries (not displayed)
---@param entry table A papis entry
---@return string search_string A string containing all the searchable information
function M.create_search_string(entry)
  local search_string = table.concat({ entry.question, entry.answer }, " "):gsub("\n", "")
  return search_string
end

---Load all ask entries from JSON files
---@return table entries List of { question, answer, contexts, ... }
function M.load_entries()
  log.debug("Loading entries")
  local dir = get_storage_dir()
  local paths = vim.fn.globpath(dir, "*.json", false, true) or {}
  local entries = {}

  for _, path in ipairs(paths) do
    local basename = fs.basename(path)
    local time_added, slash = parse_meta_from_filename(basename)

    local f = io.open(path, "r")
    if f then
      local content = f:read("*a")
      f:close()
      local ok, data = pcall(vim.json.decode, content, { luanil = { array = true, object = true } })
      if ok and type(data) == "table" then
        local entry = {
          question = data.question,
          answer = data.answer,
          contexts = data.contexts,
          references = data.references,
          time_added = time_added,
          slash = slash,
          filepath = path,
        }
        entries[#entries + 1] = entry
      else
        vim.notify("Failed to parse ask JSON: " .. basename, vim.log.levels.WARN)
      end
    end
  end

  if config["ask"].initial_sort_by_time_added then
    table.sort(entries, function(a, b)
      return a.time_added > b.time_added
    end)
  end

  if #entries == 0 then
    entries[1] = {
      placeholder = "No questions found. Type '/ask <question>' to ask a new question.",
    }
  end

  return entries
end

---Creates a preview buffer for the picker
---@param entry table The selected item
---@param buf number The buffer to create the preview in
---@param win number The window to set the preview in
function M.create_preview(entry, buf, win)
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })

  if entry.placeholder then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, placeholder_lines)
    return
  else
    entry.answer = markdown.transform_answer(entry.answer):gsub("[\n\r]", " ")
    local preview_lines = utils:make_nui_lines(config["ask"].preview_format, entry)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    for line_nr, line in ipairs(preview_lines) do
      line:render(buf, -1, line_nr)
    end
  end

  vim.api.nvim_set_option_value("wrap", true, { win = win })
  vim.api.nvim_set_option_value("number", false, { win = win })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

---Runs the command associated with the slash command
---@param slash string The slash command to run
---@param question string The question to pass to the command
function M.run_slash_command(slash, question)
  local slash_command_args = config.ask.slash_command_args
  local args = slash_command_args[slash]
  if not args then
    vim.notify("Unknown slash command: /" .. slash, vim.log.levels.WARN)
    return
  end

  local cmd = config.papis_cmd_base
  -- replace all `"{input}"` with the `question`
  if vim.tbl_contains(args, "{input}") then
    for _, v in ipairs(args) do
      cmd[#cmd + 1] = (v == "{input}") and question or v
    end
  else
    cmd = vim.list_extend({}, args)
  end

  vim.notify("Running /" .. slash .. " command", vim.log.levels.INFO)

  vim.system(cmd, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 and vim.tbl_contains(args, "json") then
        local json_str = result.stdout
        if json_str and json_str ~= "" then
          save_result(json_str, slash)
          vim.notify("Answer received and saved", vim.log.levels.INFO)
        end
      elseif result.code == 0 then
        vim.notify("/" .. slash .. " command ran successfully", vim.log.levels.INFO)
      else
        local error_msg = "/" .. slash .. " command failed with exit code: " .. result.code
        if result.stderr and result.stderr ~= "" then
          error_msg = error_msg .. "\nError: " .. result.stderr
        end
        vim.notify(error_msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

---Open a signle answer in a buffer or run slash command
---@param entry table The selected entry
function M.open_answer(entry)
  local content = markdown:to_markdown_output(entry)
  local lines = vim.split(content, "\n")

  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_win_set_buf(0, buf)
  vim.bo[buf].filetype = "markdown"
end

function M.delete_entry(entry)
  local choice = vim.fn.confirm(
    string.format("Delete ask entry?\nQuestion: %s", (entry.question or ""):sub(1, 50) .. "..."),
    "&Yes\n&No",
    2
  )

  if choice == 1 then
    delete_entry_file(entry.filepath)
    vim.notify("Ask entry deleted", vim.log.levels.INFO)
  end
end

return M
