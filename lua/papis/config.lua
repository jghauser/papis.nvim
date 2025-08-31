--
-- PAPIS | CONFIG
--
--
-- Defines all the default configuration values.
--

---@module 'sqlite'

---@class PapisConfigPickerKeymap : vim.api.keyset.keymap
---@field [1]? string
---@field mode? string|string[]

---@alias FormatEntryTable
---| { [1]: string, [2]: string|table<string, string[]>, [3]: string, [4]: string, [5]: string|table<string, string[]>, [6]: string }[]

---@class PapisConfigSearch
---@field enable boolean
---@field provider "auto"|"snacks"|"telescope"
---@field picker_keymaps table<string, PapisConfigPickerKeymap>
---@field wrap boolean
---@field initial_sort_by_time_added boolean
---@field search_keys string[]
---@field preview_format FormatEntryTable
---@field results_format FormatEntryTable

---@class PapisConfigFormatter
---@field enable boolean
---@field format_notes fun(entry: table): string[]
---@field format_references fun(entry: table): string[]

---@class PapisConfigAtCursor
---@field enable boolean
---@field popup_format table[]

---@class PapisConfigCompletion
---@field enable boolean
---@field provider "auto"|"cmp"|"blink"

---@class PapisConfigAsk
---@field enable boolean
---@field provider "auto"|"snacks"|"telescope"
---@field slash_command_args table<string, string[]>
---@field initial_sort_by_time_added boolean
---@field picker_keymaps table<string, PapisConfigPickerKeymap>
---@field preview_format FormatEntryTable
---@field results_format FormatEntryTable

---@class PapisConfigPapisStorage
---@field enable boolean
---@field key_name_conversions table<string, string>
---@field required_keys string[]

---@class PapisConfigColors
---@field enable boolean

---@class PapisConfigDebug
---@field enable boolean
---@field logging table<string, string>

---@class (exact) PapisConfigDefault
---@field cite_formats table<string, table<string, string>>
---@field cite_formats_fallback string
---@field always_use_plain boolean
---@field enable_keymaps boolean
---@field enable_fs_watcher boolean
---@field data_tbl_schema SqliteSchemaDict[]
---@field db_path string
---@field yq_bin string
---@field papis_cmd_base string[]
---@field init_filetypes string[]
---@field papis_conf_keys string[]
---@field enable_icons boolean
---@field formatter table<string, any>
---@field at-cursor table<string, any>
---@field search PapisConfigSearch
---@field completion PapisConfigCompletion
---@field ask PapisConfigAsk
---@field papis-storage PapisConfigPapisStorage
---@field colors PapisConfigColors
---@field debug PapisConfigDebug

-- default configuration values
---@type PapisConfigDefault
local default_config = {
  cite_formats = {
    tex = {
      start_str = [[\cite{]],
      start_pattern = [[\cite[pt]?%[?[^%{]*]],
      end_str = "}",
      separator_str = ", ",
    },
    markdown = {
      ref_prefix = "@",
      separator_str = "; ",
    },
    rmd = {
      ref_prefix = "@",
      separator_str = "; ",
    },
    plain = {
      separator_str = ", ",
    },
    org = {
      start_str = "[cite:",
      end_str = "]",
      ref_prefix = "@",
      separator_str = ";",
    },
    norg = {
      start_str = "{= ",
      end_str = "}",
      separator_str = "; ",
    },
    typst = {
      ref_prefix = "@",
      separator_str = " ",
    },
  },
  cite_formats_fallback = "plain",
  always_use_plain = false,
  enable_keymaps = false,
  enable_fs_watcher = true,
  data_tbl_schema = { -- only "text" and "luatable" are allowed
    id = { "integer", primary = true },
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
    related_to = "luatable",
  },
  db_path = vim.fn.stdpath("data") .. "/papis/papis-nvim.sqlite3",
  yq_bin = "yq",
  papis_cmd_base = { "papis" },
  init_filetypes = { "markdown", "norg", "yaml", "typst" },
  papis_conf_keys = { "info-name", "notes-name", "dir", "opentool" },
  enable_icons = true,
  ["formatter"] = {
    enable = true,
    format_notes = function(entry)
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
      return lines
    end,
    format_references = function(entry)
      local reference_format = {
        { "author",  "%s ",    "" },
        { "year",    "(%s). ", "" },
        { "title",   "%s. ",   "" },
        { "journal", "%s. ",   "" },
        { "volume",  "%s",     "" },
        { "number",  "(%s)",   "" },
      }
      local display_strings = require("papis.utils"):format_display_strings(entry, reference_format)
      for k, v in ipairs(display_strings) do
        display_strings[k] = v[1]
      end
      local lines = { table.concat(display_strings) }
      return lines
    end,
  },
  ["at-cursor"] = {
    enable = true,
    popup_format = {
      {
        { "author", "%s", "PapisPopupAuthor" },
        { "vspace", "vspace" },
        { "files", { related_to = { "󰌹 ", "R " }, fallback = { "󰈙 ", "F " } }, "PapisResultsFiles" },
        { "notes", { fallback = { "󰆈 ", "N " } }, "PapisResultsNotes" },
      },
      { "year",  "%s", "PapisPopupYear" },
      { "title", "%s", "PapisPopupTitle" },
    },
  },
  ["search"] = {
    enable = true,
    provider = "auto",
    picker_keymaps = {
      ["<CR>"] = { "ref_insert", mode = { "n", "i" }, desc = "(Papis) Insert ref" },
      ["r"] = { "ref_insert_formatted", mode = "n", desc = "(Papis) Insert formatted ref" },
      ["<c-r>"] = { "ref_insert_formatted", mode = "i", desc = "(Papis) Insert formatted ref" },
      ["f"] = { "open_file", mode = "n", desc = "(Papis) Open file" },
      ["<c-f>"] = { "open_file", mode = "i", desc = "(Papis) Open file" },
      ["n"] = { "open_note", mode = "n", desc = "(Papis) Open note" },
      ["<c-n>"] = { "open_note", mode = "i", desc = "(Papis) Open note" },
      ["e"] = { "open_info", mode = "n", desc = "(Papis) Open info.yaml file" },
      ["<c-e>"] = { "open_info", mode = "i", desc = "(Papis) Open info.yaml file" },
    },
    wrap = true,
    initial_sort_by_time_added = true,
    search_keys = { "author", "editor", "year", "title", "tags" }, -- also possible: "type"
    preview_format = {
      { "author", "%s", "PapisPreviewAuthor" },
      { "year", "%s", "PapisPreviewYear" },
      { "title", "%s", "PapisPreviewTitle" },
      { "empty_line" },
      { "journal", "%s", "PapisPreviewValue", "show_key", { fallback = { "󱀁  ", "%s: " } }, "PapisPreviewKey" },
      { "related_to", "%s", "PapisPreviewValue", "show_key", { fallback = { "󰌹  ", "%s: " } }, "PapisPreviewKey" },
      { "type", "%s", "PapisPreviewValue", "show_key", { fallback = { "󰀼  ", "%s: " } }, "PapisPreviewKey" },
      { "ref", "%s", "PapisPreviewValue", "show_key", { fallback = { "󰌋  ", "%s: " } }, "PapisPreviewKey" },
      { "tags", "%s", "PapisPreviewValue", "show_key", { fallback = { "󰓹  ", "%s: " } }, "PapisPreviewKey" },
      { "abstract", "%s", "PapisPreviewValue", "show_key", { fallback = { "󰭷  ", "%s: " } }, "PapisPreviewKey" },
    },
    results_format = {
      { "files", { related_to = { "󰌹 ", "R " }, fallback = { "󰈙 ", "F " } }, "PapisResultsFiles", "force_space" },
      { "notes", { fallback = { "󰆈 ", "N " } }, "PapisResultsNotes", "force_space" },
      { "author", "%s ", "PapisResultsAuthor" },
      { "year", "(%s) ", "PapisResultsYear" },
      { "title", "%s", "PapisResultsTitle" },
    },
  },
  ["completion"] = {
    enable = true,
    provider = "auto",
  },
  ["ask"] = {
    enable = false,
    provider = "auto",
    slash_command_args = {
      ask = { "ask", "--output", "json", "{input}" },
      shortask = { "ask", "--output", "json", "--evidence-k", "5", "--max-sources", "3", "{input}" },
      longask = { "ask", "--output", "json", "--evidence-k", "20", "--max-sources", "10", "{input}" },
      index = { "ask", "index" },
    },
    initial_sort_by_time_added = true,
    picker_keymaps = {
      ["<CR>"] = { "open_answer", mode = { "n", "i" }, desc = "(Papis Ask) Open answer in float" },
      ["d"] = { "delete_answer", mode = "n", desc = "(Papis Ask) Delete entry" },
      ["<c-d>"] = { "delete_answer", mode = "i", desc = "(Papis Ask) Delete entry" },
    },
    preview_format = {
      { "question", "%s", "PapisPreviewQuestion", "show_key", { fallback = { "󰍉  ", "Question: " } }, "PapisPreviewKey" },
      { "empty_line" },
      { "answer", "%s", "PapisPreviewAnswer", "show_key", { fallback = { "󱆀  ", "Answer: " } }, "PapisPreviewKey" },
    },
    results_format = {
      { "slash", {
        ask = { "󰪡  ", "M " },
        shortask = { "󰄰  ", "S" },
        longask = { "󰪥  ", "L " },
      }, "PapisResultsCommand", "force_space" },
      { "question",   "%s ",   "PapisResultsQuestion" },
      { "time_added", "(%s) ", "PapisResultsTimeAdded" },
    },
  },
  ["papis-storage"] = {
    enable = true,
    key_name_conversions = {
      time_added = "time-added",
    },
    required_keys = { "papis_id", "ref" },
  },
  ["colors"] = {
    enable = true,
  },
  ["debug"] = {
    enable = false,
    logging = {
      level = "trace",
      use_console = "false",
      use_file = "true",
    }
  },
}

---@class PapisConfig : PapisConfigDefault
local M = {}

---List of all enabled modules
---@type string[]
M.enabled_modules = {}

---Get the cite_format for the current filetype
---@return table cite_format The citation format to be used for the filetype. If table, then first is for inserting, second for parsing
function M:get_cite_format()
  local filetype = vim.bo.filetype

  local cite_formats = self.cite_formats
  local cite_formats_fallback = self.cite_formats_fallback
  local cite_format

  local fallback = {
    separator_str = ", ",
  }

  if self.always_use_plain then
    cite_format = cite_formats.plain or fallback
  else
    cite_format = cite_formats[filetype] or cite_formats[cite_formats_fallback]
  end
  return cite_format
end

---Updates the default configuration with user supplied options and gets conf from Papis
---@param opts PapisConfigDefault Same format as default_config and contains user config
function M:update(opts)
  local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

  -- add checkhealth to filetypes (so papis gets loaded there)
  table.insert(newconf.init_filetypes, "checkhealth")

  -- set main config table
  for k, v in pairs(newconf) do
    self[k] = v
  end

  -- check what modules are enabled
  local modules = {
    "formatter",
    "at-cursor",
    "search",
    "completion",
    "ask",
    "papis-storage",
    "colors",
    "debug",
  }
  for _, module_name in ipairs(modules) do
    if self[module_name].enable then
      table.insert(self.enabled_modules, module_name)
    end
  end
end

return M
