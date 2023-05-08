# 📚 papis.nvim

Papis.nvim is a [neovim](https://github.com/neovim/neovim) companion plugin for the bibliography manager [papis](https://github.com/papis/papis). It's meant for all those who do academic and other writing in neovim and who want quick access to their bibliography from within the comfort of their editor.

![20221002_18h39m59s_grim](https://user-images.githubusercontent.com/10319377/193468827-b6468f39-47f0-4b3b-aa47-4328ea2629e4.jpeg)

- Search your bibliography with [telescope](https://github.com/nvim-telescope/telescope.nvim)
- Place your cursor over a citation key and get information about the entry
- Automatically format new notes
- Tag completion in `info.yaml` files

And this is just the beginning! With its fast and always up-to-date sqlite database (courtesy of [sqlite.lua](https://github.com/tami5/sqlite.lua)), a host of [additional features](#planned-features-and-improvements) are just waiting to be implemented. My hope is for this plugin to eventually become neovim's answer to emacs plugins such as [org-ref](https://github.com/jkitchin/org-ref), [helm-bibtex](https://github.com/tmalsburg/helm-bibtex), and [citar](https://github.com/emacs-citar/citar).

This plugin is currently in early beta. Bugs and breaking changes are expected. Breaking changes are communicated in a pinned issue and commit messages.

While papis.nvim is likely buggy, it is equally likely unable to mess with your precious bibliography. First, it doesn't by itself alter your papis `info.yaml` files; it always uses the `papis` command to do so. Second, this command is currently only invoked when adding new notes to an item. Your database should therefore be safe from corruption (**however**: have backups, gremlins waiting to pounce are not my responsibility). In the future, papis.nvim might directly edit `info.yaml` files, but if and when that happens, this will be clearly communicated as a breaking change.

## Features

A number of features (bundled into `modules`) are shipped with papis.nvim. These can be (de)activated as desired.

### 'search' module

![search (trimmed)](https://user-images.githubusercontent.com/10319377/193468846-327988b0-de69-4484-887f-e294f1ed8ed8.gif)

Papis.nvim integrates with telescope to easily and quickly search one's bibliography. Open the picker and enter the title (or author, year, etc.) of the article you're looking for. Once you've found it, you can insert a citation, open attached files and notes, and edit the `info.yaml` file. When attempting to open a note where none exists, papis.nvim will ask to create a new one.

Commands:
- `:Telescope papis`: Opens the papis.nvim telescope picker

With the picker open, the following (currently hardcoded) keymaps become available:
- `o` (normal) / `c-o` (insert): Opens files attached to the entry 
- `n` (normal) / `c-n` (insert): Opens notes attached to the entry (asks for the creation of a new one if none exists)
- `e` (normal) / `c-e` (insert): Opens the `info.yaml` file

### 'completion' module

![completion (trimmed)](https://user-images.githubusercontent.com/10319377/193469045-4941bb6d-3582-4ad0-9e29-249ddc8aae46.gif)

When editing `tags` in `info.yaml` files, papis.nvim will suggest tags found in the database. This module is implemented as a [cmp](https://github.com/hrsh7th/nvim-cmp) source.

### 'cursor-actions' module

![cursor-actions (trimmed)](https://user-images.githubusercontent.com/10319377/193468973-3755f5b9-e2bb-4de9-900c-bf130ea09bad.gif)

When the cursor is positioned over a citation key (e.g. `Kant1781Critique`), papis.nvim allows you to interact with the bibliography item referenced by it.

Commands:
- `:PapisShowPopup`: Opens a floating window with information about the entry
- `:PapisOpenFile`: Opens files attached to the entry
- `:PapisOpenNote`: Opens notes attached to the entry (asks for the creation of a new one if none exists)
- `:PapisEditEntry`: Opens the `info.yaml` file

### 'formatter' module

![formatter_trimmed](https://user-images.githubusercontent.com/10319377/193469179-35e1a3b5-bad6-4289-a9ae-586dc9b3af8a.gif)

When creating new notes (via `:Telescope papis` or `:PapisOpenNote`), papis.nvim can be set up to format the new note with a custom function. You can, for example, give the note a title that corresponds to the entry's title or provide it with a skeleton structure. Below, in the setup section, there's an example suitable for the `.norg` format.

## The database

All of papis.nvim's features are made possible by a sqlite database that is created when the plugin is first started. This might take a while, so be patient. From then on, the database is automatically (and very quickly) updated whenever `info.yaml` files are added, changed, or deleted. The database is synchronised when papis.nvim is started and is then kept up-to-date continuously while at least one neovim instance with a running papis.nvim session exists.

Note that fiddling with the plugin's options can leave the database in a messy state. If strange errors appear, use `:PapisReInitData` to re-initialise the database.

## Installation

With packer:

```lua
use({
  "jghauser/papis.nvim",
  after = { "telescope.nvim", "nvim-cmp" },
  requires = {
    "kkharji/sqlite.lua",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("papis").setup(
    -- Your configuration goes here
    )
  end,
})
```

With lazy.nvim:

```lua
{
  "jghauser/papis.nvim",
  dependencies = {
    "kkharji/sqlite.lua",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("papis").setup({
    -- Your configuration goes here
    })
  end,
}
```

Additional dependencies:

- *papis*: papis.nvim is meant to be used in conjunction with papis and won't run if it doesn't find the `papis` executable. You'll need at least v0.13.
- *yq*: papis.nvim requires the [yq](https://github.com/mikefarah/yq) utility to convert `.yaml` files to `.json` (which can then be read by neovim). Note that papis.nvim doesn't (currently) support the [python yq](https://github.com/kislyuk/yq).
- *treesitter yaml parser*: Required by the completion module.

*Neovim version*: papis.nvim is being tested on the latest stable version.

*Operating system*: papis.nvim has only been tested on Linux -- but will hopefully also work on other operating systems (if you run into problems, please open an issue).

## Setup

Papis.nvim exposes a rather large number of configuration options, most of which can be left alone -- and quite a few of which probably *should* be left alone (or not, if you're feeling brave). Currently, papis.nvim doesn't check whether you've managed to set incompatible options, and weird failures will likely occur in such instances.

Note that an empty setup function should work reasonably well when just test-driving the plugin. It will, however, slow neovim startup down considerably and should be replaced with a proper configuration.

Minimal setup:

```lua
require("papis").setup({
  -- These are configuration options of the `papis` program relevant to papis.nvim.
  -- Papis.nvim can get them automatically from papis, but this is very slow. It is
  -- recommended to copy the relevant settings from your papis configuration file.
  papis_python = {
    dir = "/path/to/my/library",
    info_name = "info.yaml", -- (when setting papis options `-` is replaced with `_`
                             -- in the keys names)
    notes_name = [[notes.norg]],
  },
  -- Enable the default keymaps
  enable_keymaps = true,
})
```

Full list of configuration options (with defaults):

```lua
-- List of enabled papis.nvim modules.
enable_modules = {
  ["search"] = true,          -- Enables/disables the search module
  ["completion"] = true,      -- Enables/disables the completion module
  ["cursor-actions"] = true,  -- Enables/disables the cursor-actions module
  ["formatter"] = true,       -- Enables/disables the formatter module
  ["colors"] = true,          -- Enables/disables default highlight groups (you
                              -- probably want this)
  ["base"] = true,            -- Enables/disables the base module (you definitely
                              -- want this)
  ["debug"] = false,          -- Enables/disables the debug module (useful to
                              -- troubleshoot and diagnose issues)
},

-- Defines citation formats for various filetypes. When the value is a table, then
-- the first entry is used to insert citations, whereas the second will be used to
-- find references (e.g. by the `cursor-action` module). `%s` stands for the reference.
-- Note that the first entry is a string (where e.g. `\` needs to be excaped as `\\`)
-- and the second a lua pattern (where magic characters need to be escaped with
-- `%`; https://www.lua.org/pil/20.2.html).
cite_formats = {
  tex = { "\\cite{%s}", "\\cite[tp]?%*?{%s}" },
  markdown = "@%s",
  rmd = "@%s",
  plain = "%s",
  org = { "[cite:@%s]", "%[cite:@%s]" },
  norg = "{= %s}",
},

-- What citation format to use when none is defined for the current filetype.
cite_formats_fallback = "plain",

-- Enable default keymaps.
enable_keymaps = false,

-- Enable commands (disabling this still allows you to call the relevant lua
-- functions directly)
enable_commands = true,

-- Whether to enable the file system event watcher. When disabled, the database
-- is only updated on startup.
enable_fs_watcher = true,

-- The sqlite schema of the main `data` table. Only the "text" and "luatable"
-- types are allowed.
data_tbl_schema = {
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
  author_list = "luatable",
  tags = "luatable",
  files = "luatable",
},

-- Path to the papis.nvim database.
db_path = vim.fn.stdpath("data") .. "/papis_db/papis-nvim.sqlite3",

-- Name of the `yq` executable.
yq_bin = "yq",

-- The papis options relevant for papis.nvim (see above minimal config). By
-- default it is unset, which prompts papis.nvim to call `papis config` to 
-- get the values.
papis_python = nil,

-- Function to execute when adding a new note. `ref` is the citation key of the
-- relevant entry and `notes_name` is defined in `papis_python` above.
create_new_note_fn = function(papis_id, notes_name)
  vim.fn.system(
    string.format(
      "papis update --set notes %s papis_id:%s",
      vim.fn.shellescape(notes_name),
      vim.fn.shellescape(papis_id)
    )
  )
end,

-- Filename patterns that trigger papis.nvim to start. `%info_name%` needs to be
-- first item; it is replaced with `info_name` as defined in `papis_python`.
init_filenames = { "%info_name%", "*.md", "*.norg" },

-- Configuration of the search module.
["search"] = {

  -- Wether to enable line wrap in the telescope previewer.
  wrap = true,

  -- What keys to search for matches.
  search_keys = { "author", "editor", "year", "title", "tags" },

  -- The format for the previewer. Each line in the config represents a line in
  -- the preview. For each line, we define: 
  --   1. The key whose value is shown
  --   2. How it is formatted (here, each is just given as is)
  --   3. The highlight group
  --   4. (Optionally), `show_key` causes the key's name to be displayed in addition
  --      to the value. When used, there are then another two items defining the
  --      formatting of the key and its highlight group. The key is shown *before*
  --      the value in the preview (even though it is defined after it in this
  --      configuration (e.g. `title = Critique of Pure Reason`)).
  -- `empty_line` is used to insert an empty line
  preview_format = {
    { "author", "%s", "PapisPreviewAuthor" },
    { "year", "%s", "PapisPreviewYear" },
    { "title", "%s", "PapisPreviewTitle" },
    { "empty_line" },
    { "ref", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
    { "type", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
    { "tags", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
    { "files", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
    { "notes", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
    { "journal", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
    { "abstract", "%s", "PapisPreviewValue", "show_key", "%s = ", "PapisPreviewKey" },
  },
  
  -- The format of each line in the the results window. Here, everything is show on
  -- one line (otherwise equivalent to points 1-3 of `preview_format`).
  results_format = {
    { "author", "%s ", "PapisResultsAuthor" },
    { "year", "(%s) ", "PapisResultsYear" },
    { "title", "%s", "PapisResultsTitle" },
  },
},

-- Configuration of the cursor-actions module.
["cursor-actions"] = {

  -- The format of the popup shown on `:PapisShowPopup` (equivalent to points 1-3
  -- of `preview_format`)
  popup_format = {
    { "author", "%s", "PapisPopupAuthor" },
    { "year", "%s", "PapisPopupYear" },
    { "title", "%s", "PapisPopupTitle" },
  },
},

-- Configuration of formatter module.
["formatter"] = {

  -- This function runs when first opening a new note. The `entry` arg is a table
  -- containing all the information about the entry (see above `data_tbl_schema`).
  -- This example is meant to be used with the `.norg` filetype.
  format_notes_fn = function(entry)
    -- Some string formatting templates (see above `results_format` option for
    -- more details)
    local title_format = {
      { "author", "%s ", "" },
      { "year", "(%s) ", "" },
      { "title", "%s", "" },
    }
    -- Format the strings with information in the entry
    local title = require("papis.utils"):format_display_strings(entry, title_format)
    -- Grab only the strings (and disregard highlight groups)
    for k, v in ipairs(title) do
      title[k] = v[1]
    end
    -- Define all the lines to be inserted
    local lines = {
      "@document.meta",
      "title: " .. table.concat(title),
      "description: ",
      "categories: [",
      "  notes",
      "  academia",
      "  readings",
      "]",
      "created: " .. os.date("%Y-%m-%d"),
      "version: " .. require("neorg.config").version,
      "@end",
      "",
    }
    -- Insert the lines
    vim.api.nvim_buf_set_lines(0, 0, #lines, false, lines)
    -- Move cursor to the bottom
    vim.cmd("normal G")
  end,
},

-- Configurations relevant for parsing `info.yaml` files.
["papis-storage"] = {

  -- As lua doesn't deal well with '-', we define conversions between the format
  -- in the `info.yaml` and the format in papis.nvim's internal database.
  key_name_conversions = {
    time_added = "time-added",
  },

  -- The format used for tags. Will be determined automatically if left empty.
  -- Can be set to `tbl` (if a lua table), `,` (if comma-separated), `:` (if
  -- semi-colon separated), ` ` (if space separated).
  tag_format = nil,

  -- The keys which `.yaml` files are expected to always define. Files that are
  -- missing these keys will cause an error message and will not be added to
  -- the database.
  required_keys = { "papis_id", "ref" },
},

-- Configuration of logging.
log = {

  -- What levels to log (`off` to disable). Debug mode is more conveniently
  -- enabled in `enable_modules`.
  level = "off",

  -- How to format log strings.
  notify_format = "%s",
},
```

In order to use the cmp source, you need to add it to the sources loaded by cmp.

```lua
cmp.setup({
  sources = cmp.config.sources({
  -- your other source
  { name = "papis" },
  })
})
```

Unfortunately, treesitter indenting for `yaml` files is currently very buggy, and this sometimes messes with the papis.nvim completion module. I suggest disabling treesitter indenting for this filetype.

```lua
require("nvim-treesitter.configs").setup({
  indent = {
    enable = true,
    disable = { "yaml" },
  },
})
```

## Usage

Papis will start automatically according to the filename patterns defined in `init_filenames` (see the [setup section](#setup)). Additionally, it can also be started with `:PapisStart`. The rest of the functionality is covered in the [features section](#features).

## Keymaps

By default, papis.nvim doesn't set any keymaps (except in Telescope). You can, however, enable them by setting `enable_keymaps` to true. This provides you with the following:

- `<leader>pp` (normal) / `<c-p>p` (insert): Open the telescope picker
- `<leader>po` (normal): Open file under cursor
- `<leader>pe` (normal): Edit entry under cursor
- `<leader>pn` (normal): Open note under cursor
- `<leader>pi` (normal): Show entry info popup

## Highlights

Papis.nvim defines and links the following default highlight groups:

- `PapisPreviewAuthor`: The author field in the Telescope previewer
- `PapisPreviewYear`: The year field in the Telescope previewer
- `PapisPreviewTitle`: The title field in the Telescope previewer
- `PapisPreviewKey`: The keys in the Telescope previewer (when set with `show_key`, see the setup section).
- `PapisPreviewValue`: The values in the Telescope previewer (when set with `show_key`, see the setup section).
- `PapisResultsAuthor`: The author in the Telescope results window
- `PapisResultsYear`: The year in the Telescope results window
- `PapisResultsTitle`: The title in the Telescope results window
- `PapisPopupAuthor`: The author in the cursor action popup
- `PapisPopupYear`: The year in the cursor action popup
- `PapisPopupTitle`: The title in the cursor action popup

In order to change the colours, simply override them with whatever you desire.

## Issues/Troubleshooting

You can use `:checkhealth papis` for some basic troubleshooting. In addition, you can enable the `debug` module, which exposes the following commands and a log:

- `PapisDebugGetLogPath`: Get the path to the log file
- `PapisDebugFWStop`: Stops file watching for the current neovim instance. Helps if you want to use one particular instance to try things out, but have other neovim instances open on the system.
- `PapisDebugFWStart`: Starts file watching for the current neovim instance

Please open an issue when you find bugs!

## Contributing

I am quite new to programming and there's a million things that I want to improve and probably another million things that I *should* improve but don't yet know about. I'm more than happy about any contributions, ideas for improvements, ideas for new features, bug reports, and so on. If you have a cool idea for a new functionality you want to implement, I'd be happy to guide you through the process of creating a new module. PRs should be formatted with stylua and have emmydoc comments.

## Planned features and improvements

I'm open to suggestions and PRs. Here are some things I've thought of:

- [ ] better search
  - by entry keys (e.g. tags)
  - full text (with rga?)
  - faster!
- [ ] adding new entries (both automatic and manual)
- [ ] bib(la)tex backend (in addition to papis)
  - I'm unlikely to do this myself as I don't need it. I'd be more than happy to help with the implemention however!
- [ ] sharing functionality
- [ ] insert formatted references and bibliographies (using .csl)
- [ ] tests
- [ ] make more modular
