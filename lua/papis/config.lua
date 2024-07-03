--
-- PAPIS | CONFIG
--
--
-- Defines all the default configuration values.
--

-- default configuration values
local default_config = {
  enable_modules = {
    ["at-cursor"] = true,
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
  enable_fs_watcher = true,
  data_tbl_schema = { -- only "text" and "luatable" are allowed
    id = { "integer", pk = true },
    papis_id = { "text", required = true, unique = true },
    ref = { "text", required = true, unique = true },
    author = "text",
    editor = "text",
    year = "text",
    title = "text",
    shorttitle = "text",
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
    local testing_session = require("papis.config").enable_modules["testing"]
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
  enable_icons = true,
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
  ["at-cursor"] = {
    popup_format = {
      {
        { "author", "%s", "PapisPopupAuthor" },
        { "vspace", "vspace" },
        { "files", { " ", "F " }, "PapisResultsFiles" },
        { "notes", { "󰆈 ", "N " }, "PapisResultsNotes" },
      },
      { "year",  "%s", "PapisPopupYear" },
      { "title", "%s", "PapisPopupTitle" },
    },
  },
  ["search"] = {
    wrap = true,
    initial_sort_by_time_added = true,
    search_keys = { "author", "editor", "year", "title", "tags" }, -- also possible: "type"
    preview_format = {
      { "author", "%s", "PapisPreviewAuthor" },
      { "year", "%s", "PapisPreviewYear" },
      { "title", "%s", "PapisPreviewTitle" },
      { "empty_line" },
      { "journal", "%s", "PapisPreviewValue", "show_key", { "󱀁  ", "%s: " }, "PapisPreviewKey" },
      { "type", "%s", "PapisPreviewValue", "show_key", { "󰀼  ", "%s: " }, "PapisPreviewKey" },
      { "ref", "%s", "PapisPreviewValue", "show_key", { "󰌋  ", "%s: " }, "PapisPreviewKey" },
      { "tags", "%s", "PapisPreviewValue", "show_key", { "󰓹  ", "%s: " }, "PapisPreviewKey" },
      { "abstract", "%s", "PapisPreviewValue", "show_key", { "󰭷  ", "%s: " }, "PapisPreviewKey" },
    },
    results_format = {
      { "files", { "󰈙 ", "F " }, "PapisResultsFiles", "force_space" },
      { "notes", { "󰆈 ", "N " }, "PapisResultsNotes", "force_space" },
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
    level = "info", -- off turns it off
  },
}

local M = vim.deepcopy(default_config)

---Updates the default configuration with user supplied options and gets conf from Papis
---@param opts table #Same format as default_config and contains user config
function M:update(opts)
  local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

  -- set disabled modules to nil if false
  for module_name, is_enabled in pairs(newconf.enable_modules) do
    if is_enabled == false then
      newconf.enable_modules[module_name] = nil
    end
  end

  -- add checkhealth to filetypes (so papis gets loaded there)
  table.insert(newconf.init_filetypes, "checkhealth")

  -- if debug mode is on, log level should be at least debug
  if newconf.enable_modules["debug"] == true then
    newconf.log = {
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
