--
-- PAPIS | CONFIG
--
--
-- Defines all the default configuration values.
--

-- default configuration values
local default_config = {
  enable_modules = {
    ["cursor-actions"] = true,
    ["search"] = true,
    ["completion"] = true,
    ["formatter"] = true,
    ["colors"] = true,
    ["base"] = true,
    ["debug"] = false,
    ["testing"] = false,
  }, -- can be set to nil or false or left out
  cite_formats = {
    tex = { "\\cite{%s}", "\\cite[tp]?%*?{%s}" },
    markdown = "@%s",
    rmd = "@%s",
    plain = "%s",
    org = { "[cite:@%s]", "%[cite:@%s]" },
    norg = "{= %s}",
  },
  cite_formats_fallback = "plain",
  always_use_plain = false,
  enable_keymaps = false,
  enable_commands = true,
  enable_fs_watcher = true,
  data_tbl_schema = { -- only "text" and "luatable" are allowed
    id = { "integer", pk = true },
    papis_id = { "text", required = true, unique = true },
    ref = { "text", required = true, unique = true },
    author = "text",
    editor = "text",
    year = "text",
    title = "text",
    type = "text",
    abstract = "text",
    time_added = "text",
    notes = "luatable",
    journal = "text",
    volume = "text",
    number = "text",
    author_list = "luatable",
    tags = "luatable",
    files = "luatable",
  },
  db_path = vim.fn.stdpath("data") .. "/papis_db/papis-nvim.sqlite3",
  yq_bin = "yq",
  create_new_note_fn = function(papis_id, notes_name)
    local testing_session = require("papis.config")["enable_modules"]["testing"]
    local testing_conf_path = ""
    if testing_session then
      testing_conf_path = "-c ./tests/papis_config "
    end
    vim.fn.system(
      string.format(
        "papis " .. testing_conf_path .. "update --set notes %s papis_id:%s",
        vim.fn.shellescape(notes_name),
        vim.fn.shellescape(papis_id)
      )
    )
  end,
  init_filetypes = { "markdown", "norg", "yaml" },
  papis_conf_keys = { "info-name", "notes-name", "dir", "opentool" },
  ["formatter"] = {
    format_notes_fn = function(entry)
      local title_format = {
        { "author", "%s ",   "" },
        { "year",   "(%s) ", "" },
        { "title",  "%s",    "" },
      }
      local title = require("papis.utils"):format_display_strings(entry, title_format, true)
      for k, v in ipairs(title) do
        title[k] = v[1]
      end
      local lines = {
        "---",
        'title: "Notes -- ' .. table.concat(title) .. '"',
        "---",
        "",
      }
      vim.api.nvim_buf_set_lines(0, 0, #lines, false, lines)
      vim.cmd("normal G")
    end,
    format_references_fn = function(entry)
      local reference_format = {
        { "author",  "%s ",    "" },
        { "year",    "(%s). ", "" },
        { "title",   "%s. ",   "" },
        { "journal", "%s. ",   "" },
        { "volume",  "%s",     "" },
        { "number",  "(%s)",   "" },
      }
      local reference_data = require("papis.utils"):format_display_strings(entry, reference_format)
      for k, v in ipairs(reference_data) do
        reference_data[k] = v[1]
      end
      return table.concat(reference_data)
    end,
  },
  ["cursor-actions"] = {
    popup_format = {
      { "author", "%s", "PapisPopupAuthor" },
      { "year",   "%s", "PapisPopupYear" },
      { "title",  "%s", "PapisPopupTitle" },
    },
  },
  ["search"] = {
    wrap = true,
    initial_sort_by_time_added = true,
    search_keys = { "author", "editor", "year", "title", "tags" }, -- also possible: "type"
    preview_format = {
      { "author",    "%s", "PapisPreviewAuthor" },
      { "year",      "%s", "PapisPreviewYear" },
      { "title",     "%s", "PapisPreviewTitle" },
      { "empty_line" },
      { "ref",       "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
      { "type",      "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
      { "tags",      "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
      { "files",     "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
      { "notes",     "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
      { "journal",   "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
      { "abstract",  "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
    },
    results_format = {
      { "author", "%s ",   "PapisResultsAuthor" },
      { "year",   "(%s) ", "PapisResultsYear" },
      { "title",  "%s",    "PapisResultsTitle" },
    },
  },
  ["papis-storage"] = {
    key_name_conversions = {
      time_added = "time-added",
    },
    tag_format = nil,
    required_keys = { "papis_id", "ref" },
  },
  log = {
    level = "info", -- off turns it off
  },
}

---Queries Papis to get various options.
---@param papis_conf_keys table #A table with keys to query from Papis
---@param is_testing_session boolean #If true, will use testing papis conf
---@return table #A table { info_name = val, dir = val }
local function get_papis_py_conf(papis_conf_keys, is_testing_session)
  local papis_py_conf_new = {}
  local testing_conf_path = ""
  if is_testing_session then
    testing_conf_path = "-c ./tests/papis_config "
  end
  for _, key in ipairs(papis_conf_keys) do
    local handle = io.popen("papis " .. testing_conf_path .. "config " .. key)
    if handle then
      papis_py_conf_new[string.gsub(key, "-", "_")] = string.gsub(handle:read("*a"), "\n", "")
      handle:close()
    end
  end
  if papis_py_conf_new["dir"] then
    local dir = papis_py_conf_new["dir"]
    if string.sub(dir, 1, 1) == "~" then
      dir = os.getenv("HOME") .. string.sub(dir, 2, #dir)
    end
    papis_py_conf_new["dir"] = dir
  end
  return papis_py_conf_new
end

local M = vim.deepcopy(default_config)

---Compares and updates Queries papis to get info-name and dir settings. It is very slow and shouldn't be used
---if possible.
function M:update_papis_py_conf()
  local db = require("papis.sqlite-wrapper")
  if not db then
    return
  end

  local is_testing_session = self["enable_modules"]["testing"]
  local papis_conf_keys = self["papis_conf_keys"]
  local papis_py_conf_new = get_papis_py_conf(papis_conf_keys, is_testing_session)
  local papis_py_conf_old = db.config:get()[1]
  papis_py_conf_old["id"] = nil

  local log = require("papis.log")
  if not vim.deep_equal(papis_py_conf_new, papis_py_conf_old) then
    db.config:drop()
    db.config:update({ id = 1 }, papis_py_conf_new)
    log.info("Configuration has changed. Please close all instances of neovim and run `:PapisReInitData`")
  else
    log.info("Configuration hasn't changed. No action required.")
  end
end

---Sets up Papis configuration values if not already done.
function M:setup_papis_py_conf()
  local db = require("papis.sqlite-wrapper")
  if not db then
    return
  end
  local log = require("papis.log")

  -- get config from Papis if not already in db
  if not db.config:is_setup() then
    log.info("Papis.nvim configuration not setup, importing values from Papis now")
    local is_testing_session = self["enable_modules"]["testing"]
    local papis_conf_keys = self["papis_conf_keys"]
    local papis_py_conf_new = get_papis_py_conf(papis_conf_keys, is_testing_session)
    db.config:drop()
    db.config:update({ id = 1 }, papis_py_conf_new)
  end
end

---Updates the default configuration with user supplied options and gets conf from Papis
---@param opts table #Same format as default_config and contains user config
function M:update(opts)
  local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

  -- set disabled modules to nil if false
  for module_name, is_enabled in pairs(newconf["enable_modules"]) do
    if is_enabled == false then
      newconf.enable_modules[module_name] = nil
    end
  end

  -- if debug mode is on, log level should be at least debug
  if newconf["enable_modules"]["debug"] == true then
    newconf["log"] = {
      level = "trace",
      use_console = "false",
      use_file = "true",
    }
  end

  -- set main config table
  for k, v in pairs(newconf) do
    self[k] = v
  end
end

return M
