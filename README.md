<div align="center">

<img src="resources/logo.svg" width=300>

# papis.nvim

Manage your bibliography from within your favourite editor

</div>

<br>

Papis.nvim is a [neovim](https://github.com/neovim/neovim) companion plugin for the bibliography manager [Papis](https://github.com/papis/papis). It's meant for all those who do academic and other writing in neovim and who want quick access to their bibliography from within the comfort of their editor.

![Papis search](https://github.com/jghauser/papis.nvim/assets/10319377/dd7bad33-762c-41dd-9eca-9538d6117ac1)

- Search your bibliography
- Place your cursor over a citation key and get information about the entry
- Automatically format new notes
- Tag completion in `info.yaml` files
- Insert formatted references

And this is just the beginning! With its fast and always up-to-date sqlite database (courtesy of [sqlite.lua](https://github.com/tami5/sqlite.lua)), a host of [additional features](#planned-features-and-improvements) are just waiting to be implemented. My hope is for this plugin to eventually become neovim's answer to emacs plugins such as [org-ref](https://github.com/jkitchin/org-ref), [helm-bibtex](https://github.com/tmalsburg/helm-bibtex), and [citar](https://github.com/emacs-citar/citar).

This plugin is in beta and breaking changes are expected. Breaking changes are communicated in a pinned issue and commit messages.

## Features

A number of features (bundled into `modules`) are shipped with papis.nvim. These can be (de)activated as desired.

### *Search* module

![search (trimmed)](https://user-images.githubusercontent.com/10319377/193468846-327988b0-de69-4484-887f-e294f1ed8ed8.gif)

Papis.nvim integrates with telescope and snacks to easily and quickly search your bibliography. Open the picker and enter the title (or author, year, etc.) of the article you're looking for. Once you've found it, you can insert a citation, open attached files and notes, and edit the `info.yaml` file. When attempting to open a note where none exists, papis.nvim will ask to create a new one.

Commands:

- `:Papis search`: Opens the papis.nvim picker

### *Completion* module

![completion (trimmed)](https://user-images.githubusercontent.com/10319377/193469045-4941bb6d-3582-4ad0-9e29-249ddc8aae46.gif)

When editing `tags` in `info.yaml` files, papis.nvim will suggest tags found in the database. This module is implemented as a [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) or [blink.cmp](https://github.com/Saghen/blink.cmp) source.

### *At-cursor* module

![at-cursor (trimmed)](https://user-images.githubusercontent.com/10319377/193468973-3755f5b9-e2bb-4de9-900c-bf130ea09bad.gif)

When the cursor is positioned over a citation key (e.g. `Kant1781Critique`), papis.nvim allows you to interact with the bibliography item referenced by it.

Commands:

- `:Papis at-cursor show-popup`: Opens a floating window with information about the entry
- `:Papis at-cursor open-file`: Opens files attached to the entry
- `:Papis at-cursor open-note`: Opens notes attached to the entry (asks for the creation of a new one if none exists)
- `:Papis at-cursor edit`: Opens the `info.yaml` file

### *Formatter* module

![formatter_trimmed](https://user-images.githubusercontent.com/10319377/193469179-35e1a3b5-bad6-4289-a9ae-586dc9b3af8a.gif)

When creating new notes (via `:Papis search` or `:Papis at-cursor open-note`), papis.nvim can be set up to format the new note with a custom function. You can, for example, give the note a title that corresponds to the entry's title or provide it with a skeleton structure. Below, in the setup section, there's an example suitable for the `markdown` format.

## The database

All of papis.nvim's features are made possible by a sqlite database that is created when you run `:Papis reload data`. This might take a while, so be patient. From then on, the database is automatically (and very quickly) updated whenever `info.yaml` files are added, changed, or deleted. The database is synchronised when papis.nvim is started and is then kept up-to-date continuously while at least one neovim instance with a running papis.nvim session exists.

Note that fiddling with the plugin's options can leave the database in a messy state. If strange errors appear, use `:Papis reload data` to re-initialise the database.

## Installation

Note that papis.nvim is only tested with the latest stable version of Neovim. It should work across various OSs, but most development has been done on Linux (do feel free to open issues if you run into trouble on non-Linux systems). An installation of Papis is required.

To run, papis.nvim requires:

- [`yq`](https://github.com/mikefarah/yq). This is used to convert `.yaml` files to `.json` (which can then be read by neovim). Note that papis.nvim doesn't (currently) support the [python yq](https://github.com/kislyuk/yq).
- `sqlite`. Needed by the `sqlite.lua` dependency.

Optionally, you'll need:

- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) for increased prettiness.

### Neovim package managers

In addition to the below snippets, you might also need to install:
- *treesitter yaml parser* (if you want the completion module)

<details>
  <summary>rocks.nvim</summary>

```vim
:Rocks install papis.nvim
```

Additionally, may want to install `telescope.nvim` or `snacks.nvim` (for search) and `nvim-cmp` (for completion).

</details>

<details>
  <summary>lazy.nvim</summary>

```lua
{
  "jghauser/papis.nvim",
  dependencies = {
    "kkharji/sqlite.lua",
    "MunifTanjim/nui.nvim",
    "pysan3/pathlib.nvim",
    "nvim-neotest/nvim-nio",
    -- if not already installed, you may also want:
    -- "hrsh7th/nvim-cmp",

    -- Choose one of the following two if not already installed:
    -- "nvim-telescope/telescope.nvim",
    -- "folke/snacks.nvim",

  },
  config = function()
    require("papis").setup({
    -- Your configuration goes here
    })
  end,
}
```

</details>

<details>
  <summary>packer</summary>

```lua
use({
  "jghauser/papis.nvim",
  after = { "telescope.nvim", "nvim-cmp" }, -- Amend if you're using snacks.nvim
  requires = {
    "kkharji/sqlite.lua",
    "MunifTanjim/nui.nvim",
    "pysan3/pathlib.nvim",
    "nvim-neotest/nvim-nio",
    -- if not already installed, you may also want:
    -- "hrsh7th/nvim-cmp",

    -- Choose one of the following two if not already installed:
    -- "nvim-telescope/telescope.nvim",
    -- "folke/snacks.nvim",
  },
  config = function()
    require("papis").setup(
    -- Your configuration goes here
    )
  end,
})
```

</details>

### Nix

The released version of papis.nvim can be installed with the `vimPlugins.papis-nvim` package. Alternatively, you can use the included flake to install the development version via an overlay. With `home-manager`, this can be achieved with something along the following lines:

<details>
  <summary>Nix configuration</summary>

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    papis-nvim.url = "github:jghauser/papis.nvim";
  };
  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        home-manager.nixosModules.home-manager
        {
          nixpkgs.overlays = [ papis-nvim.overlays.default ];
          home-manager.users.myuser = {
            programs.neovim = {
              enable = true;
              extraPackages = [
                pkgs.yq-go
              ];
              plugins = with pkgs.vimPlugins; [
                papis-nvim
                # if not already installed, you may also want:
                # nvim-cmp",

                # choose one of the following:
                # telescope-nvim,
                # snacks-nvim,
              ]
            };
          };
        }
      ];
    };
  };
}
```

</details>

## Setup

Papis.nvim exposes a rather large number of configuration options, most of which can be left alone -- and quite a few of which probably *should* be left alone (or not, if you're feeling brave). Currently, papis.nvim doesn't check whether you've managed to set incompatible options, and weird failures will likely occur in such instances.

Minimal setup:

```lua
require("papis").setup({
  -- Enable the default keymaps (defaults to `false`)
  enable_keymaps = true,
  -- You might want to change the filetypes activating papis.nvim
  -- init_filetypes = { "markdown", "norg", "yaml", "typst" },
  -- If you don't have an appropriate font (like Nerd Font), you
  -- may want to disable icons. This may require a `:Papis reload data`.
  -- to take effect.
  -- enable_icons = false,
})
```

<details>
  <summary>All configuration options (with defaults)</summary>

```lua
-- List of enabled papis.nvim modules.
enable_modules = {
  ["search"] = true,          -- Enables/disables the search module
  ["completion"] = true,      -- Enables/disables the completion module
  ["at-cursor"] = true,  -- Enables/disables the at-cursor module
  ["formatter"] = true,       -- Enables/disables the formatter module
  ["colors"] = true,          -- Enables/disables default highlight groups (you
                              -- probably want this)
  ["base"] = true,            -- Enables/disables the base module (you definitely
                              -- want this)
  ["debug"] = false,          -- Enables/disables the debug module (useful to
                              -- troubleshoot and diagnose issues)
},

-- Defines citation formats for various filetypes. They define how citation strings
-- are parsed and formatted when inserted. For each filetype, we may define:
-- - `start_str`: Precedes the citation.
-- - `start_pattern`: Alternative lua pattern for more complex parsing.
-- - `end_str`: Appended after the citation.
-- - `ref_prefix`: Precedes each `ref` in a citation.
-- - `separator_str`: Gets added between `ref`s if there are multiple in a citation.
-- For example, for the `org` filetype if we insert a citation with `Ref1` and `Ref2`,
-- we end up with `[cite:@Ref1;@Ref2]`.
cite_formats = {
  tex = {
    start_str = [[\cite{]],
    start_pattern = [[\cite[pt]?%[?[^%{]*]],
    end_str = "}",
    separator_str = ", ",
  },
  markdown = {
    ref_prefix = "@",
    separator_str = "; "
  },
  rmd = {
    ref_prefix = "@",
    separator_str = "; "
  },
  plain = {
    separator_str = ", "
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

-- What citation format to use when none is defined for the current filetype.
cite_formats_fallback = "plain",

-- Enable default keymaps.
enable_keymaps = false,

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

-- Path to the papis.nvim database.
db_path = vim.fn.stdpath("data") .. "/papis/papis-nvim.sqlite3",

-- Name of the `yq` executable.
yq_bin = "yq",

-- Function to execute when adding a new note. `ref` is the citation key of the
-- relevant entry and `notes_name` is the name of the notes file.
create_new_note_fn = function(papis_id, notes_name)
  vim.fn.system(
    string.format(
      "papis update --set notes %s papis_id:%s",
      vim.fn.shellescape(notes_name),
      vim.fn.shellescape(papis_id)
    )
  )
end,

-- Filetypes that start papis.nvim.
init_filetypes = { "markdown", "norg", "yaml", "typst" },

-- Papis options to import into papis.nvim.
papis_conf_keys = { "info-name", "notes-name", "dir", "opentool" },

-- Whether to enable pretty icons (requires something like Nerd Fonts)
enable_icons = true,

-- Configuration of the search module.
["search"] = {

  -- Picker provider
  provider = "auto", ---@type "auto" | "snacks" | "telescope"

  -- Picker keymaps
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

  -- Whether to enable line wrap in picker previewer.
  wrap = true,

  -- Whether to initially sort entries by time-added.
  initial_sort_by_time_added = true,

  -- What keys to search for matches.
  search_keys = { "author", "editor", "year", "title", "tags" },

  -- Papis.nvim uses a common configuration format for defining the formatting
  -- of strings. Sometimes -- as for instance in the below `preview_format` option --
  -- we define a set of lines. At other times -- as for instance in the `results_format`
  -- option -- we define a single line. Sets of lines are composed of single lines.
  -- A line can be composed of either a single element or multiple elements. The below
  -- `preview_format` shows an example where each line is defined by a table with just
  -- one element. The `results_format` and `popup_format` are examples where (some) of
  -- the lines contain multiple elements (and are represented by a table of tables).
  -- Each element contains:
  --   1. The key whose value is shown
  --   2. How it is formatted (here, each is just given as is)
  --   3. The highlight group
  --   4. (Optionally), `show_key` causes the key's name to be displayed in addition
  --      to the value. When used, there are then another two items defining the
  --      formatting of the key and its highlight group. The key is shown *before*
  --      the value in the preview (even though it is defined after it in this
  --      configuration (e.g. `title = Critique of Pure Reason`)).
  -- An element may also just contain `empty_line`. This is used to insert an empty line
  -- Strings that define the formatting (such as in 2. and 4. above) can optionally
  -- be a table, defining, first, an icon, and second, a non-icon version. The
  -- `enable_icons` option determines what is used.
  preview_format = {
    { "author", "%s", "PapisPreviewAuthor" },
    { "year", "%s", "PapisPreviewYear" },
    { "title", "%s", "PapisPreviewTitle" },
    { "empty_line" },
    { "journal", "%s", "PapisPreviewValue", "show_key", { "󱀁  ", "%s: " }, "PapisPreviewKey" },
    { "type", "%s", "PapisPreviewValue", "show_key", { "  ", "%s: " }, "PapisPreviewKey" },
    { "ref", "%s", "PapisPreviewValue", "show_key", { "  ", "%s: " }, "PapisPreviewKey" },
    { "tags", "%s", "PapisPreviewValue", "show_key", { "  ", "%s: " }, "PapisPreviewKey" },
    { "abstract", "%s", "PapisPreviewValue", "show_key", { "󰭷  ", "%s: " }, "PapisPreviewKey" },
  },

  -- The format of each line in the the results window. Here, everything is show on
  -- one line (otherwise equivalent to points 1-3 of `preview_format`). The `force_space`
  -- value is used to force whitespace for icons (so that if e.g. a file is absent, it will
  -- show "  ", ensuring that columns are aligned.)
  results_format = {
    { "files", { " ", "F " }, "PapisResultsFiles", "force_space" },
    { "notes", { "󰆈 ", "N " }, "PapisResultsNotes", "force_space" },
    { "author", "%s ", "PapisResultsAuthor" },
    { "year", "(%s) ", "PapisResultsYear" },
    { "title", "%s", "PapisResultsTitle" },
  },
},

-- Configuration of the completion module.
["completion"] = {

  -- Set the completion provider.
  provider = "auto", ---@type "auto" | "cmp" | "blink"
},

-- Configuration of the at-cursor module.
["at-cursor"] = {

  -- The format of the popup shown on `:Papis at-cursor show-popup` (equivalent to points 1-3
  -- of `preview_format`). Note that one of the lines is composed of multiple elements. Note
  -- also the `{ "vspace", "vspace" },` line which is exclusive to `popup_format` and which tells
  -- papis.nvim to fill the space between the previous and next element with whitespace (and
  -- in effect make whatever comes after right-aligned). It can only occur once in a line.
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

-- Configuration of formatter module.
["formatter"] = {

  -- This function runs when first opening a new note. The `entry` arg is a table
  -- containing all the information about the entry (see above `data_tbl_schema`).
  -- This example is meant to be used with the `markdown` filetype. The function
  -- must return a set of lines, specifying the lines to be added to the note.
  format_notes = function(entry)
    -- Some string formatting templates (see above `results_format` option for
    -- more details)
    local title_format = {
      { "author", "%s ", "" },
      { "year", "(%s) ", "" },
      { "title", "%s", "" },
    }
    -- Format the strings with information in the entry
    local title = require("papis.utils"):format_display_strings(entry, title_format, true)
    -- Grab only the strings (and disregard highlight groups)
    for k, v in ipairs(title) do
      title[k] = v[1]
    end
    -- Define all the lines to be inserted
    local lines = {
      "---",
      'title: "Notes -- ' .. table.concat(title) .. '"',
      "---",
      "",
    }
    return lines
  end,
  -- This function runs when inserting a formatted reference (currently by `f/c-f` in
  -- the picker). It works similarly to the `format_notes` above, except that the set
  -- of lines should only contain one line (references using multiple lines aren't
  -- currently supported).
  format_references = function(entry)
    local reference_format = {
      { "author",  "%s ",   "" },
      { "year",    "(%s). ", "" },
      { "title",   "%s. ",  "" },
      { "journal", "%s. ",    "" },
      { "volume",  "%s",    "" },
      { "number",  "(%s)",  "" },
    }
    local reference_data = require("papis.utils"):format_display_strings(entry, reference_format)
    for k, v in ipairs(reference_data) do
      reference_data[k] = v[1]
    end
    local lines = { table.concat(reference_data) }
    return lines
  end,
},

-- Configurations relevant for parsing `info.yaml` files.
["papis-storage"] = {

  -- As lua doesn't deal well with '-', we define conversions between the format
  -- in the `info.yaml` and the format in papis.nvim's internal database.
  key_name_conversions = {
    time_added = "time-added",
  },

  -- The keys which `.yaml` files are expected to always define. Files that are
  -- missing these keys will cause an error message and will not be added to
  -- the database.
  required_keys = { "papis_id", "ref" },
},
```

To use the blink.cmp source, you need to add it to the list of default sources:

```lua
require("blink.cmp").setup({
  sources = {
    -- add 'papis' to the list of sources for the yaml filetype
    per_filetype = {
      yaml = { "papis" }
    },
})
```

Similarly, to use the cmp.nvim source:

```lua
require("cmp").setup({
  sources = cmp.config.sources({
  -- your other source
  { name = "papis" },
  })
})
```

</details>

## Usage

Papis.nvim will start automatically according to the filetypes defined in `init_filetypes` (see the [setup section](#setup)). When first starting, papis.nvim will import some configuration values from Papis and save them in the database. It will then prompt you to run `:Papis reload data` to import all of your library into the database. If you update your Papis configuration, you should re-import the configuration into papis.nvim with `:Papis reload config` and run `:Papis reload data` again.

## Keymaps

By default, papis.nvim doesn't set any keymaps (except in the picker). You can, however, enable them by setting `enable_keymaps` to true. This provides you with the following:

- `<leader>pp` (normal) / `<c-o>p` (insert): Open the picker
- `<leader>pf` (normal): Open file under cursor
- `<leader>pe` (normal): Edit entry under cursor
- `<leader>pn` (normal): Open note under cursor
- `<leader>pi` (normal): Show entry info popup

## Highlights

Papis.nvim defines and links a number of default highlight groups. In order to change the colours, simply override them with whatever you desire.

<details>
  <summary>Highlight groups</summary>

- `PapisPreviewAuthor`: The author field in the picker previewer
- `PapisPreviewYear`: The year field in the picker previewer
- `PapisPreviewTitle`: The title field in the picker previewer
- `PapisPreviewKey`: The keys in the picker previewer (when set with `show_key`, see the setup section).
- `PapisPreviewValue`: The values in the picker previewer (when set with `show_key`, see the setup section).
- `PapisResultsAuthor`: The author in the picker results window
- `PapisResultsYear`: The year in the picker results window
- `PapisResultsTitle`: The title in the picker results window
- `PapisResultsFiles`: The files in the picker results window
- `PapisResultsNotes`: The notes in the picker results window
- `PapisPopupAuthor`: The author in the cursor action popup
- `PapisPopupYear`: The year in the cursor action popup
- `PapisPopupTitle`: The title in the cursor action popup

</details>

## Issues/Troubleshooting

You can use `:checkhealth papis` for some basic troubleshooting. Make sure to open a file of a type configured in `init_filetypes` before calling `checkhealth`, so that papis.nvim is properly loaded. In addition, you can enable the `debug` module, which exposes the following commands and a log:

- `:Papis debug info`: Get the path to the log file
- `:Papis debug stop-watchers`: Stops file watching for the current neovim instance. Helps if you want to use one particular instance to try things out, but have other neovim instances open on the system.
- `:Papis debug start-watchers`: Starts file watching for the current neovim instance

Please open an issue when you find bugs!

## Contributing

I am quite new to programming and there's a million things that I want to improve and probably another million things that I *should* improve but don't yet know about. I'm more than happy about any contributions, ideas for improvements, ideas for new features, bug reports, and so on. If you have a cool idea for a new functionality you want to implement, I'd be happy to guide you through the process of creating a new module. PRs should be formatted to have indents of 2 spaces and have emmydoc comments.

## Planned features and improvements

I'm open to suggestions and PRs. Here are some things I've thought of:

- [ ] better search
  - by entry keys (e.g. tags)
  - full text (with rga?)
- [ ] adding new entries (both automatic and manual)
- [ ] bib(la)tex backend (in addition to Papis)
  - I'm unlikely to do this myself as I don't need it. I'd be more than happy to help with the implemention however!
- [ ] sharing functionality
- [ ] insert formatted references and bibliographies (using .csl)
- [ ] tests

## Thanks

Big thanks to [Irteza Rehman](https://www.irtezarehman.com/) for generously contributing the beautiful logo.
