--
-- PAPIS | CONFIG
--
--
-- Defines all the default configuration values.
--

---Queries papis to get info-name and dir settings. It is very slow and shouldn't be used
---if possible.
---@return table #A table { info_name = val, dir = val }
local function get_papis_py_conf()
  local keys_to_get = { "info-name", "notes-name", "dir" }
  local papis_py_conf = {}
  for _, key in ipairs(keys_to_get) do
    local handle = io.popen("papis config " .. key)
    if handle then
      papis_py_conf[string.gsub(key, "-", "_")] = string.gsub(handle:read("*a"), "\n", "")
      handle:close()
    end
    if papis_py_conf["dir"] then
      local dir = papis_py_conf["dir"]
      if string.sub(dir, 1, 1) == "~" then
        dir = os.getenv("HOME") .. string.sub(dir, 2, #dir)
      end
      papis_py_conf["dir"] = dir
    end
  end
  return papis_py_conf
end

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
  papis_python = nil,
  create_new_note_fn = function(papis_id, notes_name)
    vim.fn.system(
      string.format(
        "papis update --set notes %s papis_id:%s",
        vim.fn.shellescape(notes_name),
        vim.fn.shellescape(papis_id)
      )
    )
  end,
  init_filenames = { "%info_name%", "*.md", "*.norg" }, -- if %info_name%, then needs to be at first position
  ["formatter"] = {
    format_notes_fn = function(entry)
      local title_format = {
        { "author", "%s ", "" },
        { "year", "(%s) ", "" },
        { "title", "%s", "" },
      }
      local title = require("papis.utils"):format_display_strings(entry, title_format)
      for k, v in ipairs(title) do
        title[k] = v[1]
      end
      local lines = {
        "@document.meta",
        "title: " .. table.concat(title),
        "categories: [",
        "  notes",
        "  academia",
        "  readings",
        "]",
        "created: " .. os.date("%Y-%m-%d"),
        "updated: " .. os.date("%Y-%m-%d"),
        "version: " .. require("neorg.core.config").norg_version,
        "@end",
        "",
      }
      vim.api.nvim_buf_set_lines(0, 0, #lines, false, lines)
      vim.cmd("normal G")
    end,
    format_references_fn = function(entry)
      local reference_format = {
        { "author",  "%s ",   "" },
        { "year",    "(%s). ", "" },
        { "title",   "%s. ",  "" },
        { "journal", "%s. ",    "" },   -- TODO: italicize
        { "volume",  "%s",    "" },   -- TODO: italicize
        { "number",  "(%s)",  "" },
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
      { "year", "%s", "PapisPopupYear" },
      { "title", "%s", "PapisPopupTitle" },
    },
  },
  ["search"] = {
    wrap = true,
    search_keys = { "author", "editor", "year", "title", "tags" }, -- also possible: "type"
    preview_format = {
      { "author", "%s", "PapisPreviewAuthor" },
      { "year", "%s", "PapisPreviewYear" },
      { "title", "%s", "PapisPreviewTitle" },
      { "empty_line" },
      { "ref", "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
      { "type", "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
      { "tags", "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
      { "files", "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
      { "notes", "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
      { "journal", "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
      { "abstract", "%s", "PapisPreviewValue", "show_key", "%s: ", "PapisPreviewKey" },
    },
    results_format = {
      { "author", "%s ", "PapisResultsAuthor" },
      { "year", "(%s) ", "PapisResultsYear" },
      { "title", "%s", "PapisResultsTitle" },
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
    level = "off", -- off turns it off
    notify_format = "%s",
  },
}

local M = vim.deepcopy(default_config)

---Updates the default configuration with user supplied options
---@param opts table #Same format as default_config and contains user config
function M:update(opts)
  local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

  -- get papis options if not explicitly given in setup
  if not newconf["papis_python"] then
    newconf["papis_python"] = get_papis_py_conf()
  end

  -- set disabled modules to nil if false
  for module_name, is_enabled in pairs(newconf["enable_modules"]) do
    if is_enabled == false then
      newconf.enable_modules[module_name] = nil
    end
  end

  -- replace %info_name% with actual value
  if newconf["init_filenames"][1] == "%info_name%" then
    table.remove(newconf["init_filenames"], 1)
    table.insert(newconf["init_filenames"], newconf["papis_python"]["info_name"])
  end

  -- if debug mode is on, log level should be at least debug
  if newconf["enable_modules"]["debug"] == true then
    if newconf["log"]["level"] ~= "trace" then
      newconf["log"]["level"] = "debug"
    end
  end

  for k, v in pairs(newconf) do
    self[k] = v
  end
end

return M
