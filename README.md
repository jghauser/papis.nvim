<div align="center">

<img src="resources/logo.svg" width=300>

# papis.nvim

Manage your bibliography from within your favourite editor

</div>

<br>

Papis.nvim is a [Neovim](https://github.com/neovim/neovim) companion plugin for the bibliography manager [Papis](https://github.com/papis/papis). It's meant for all those who do academic and other writing in Neovim and who want quick access to their bibliography from within the comfort of their editor.

![Papis search](https://github.com/user-attachments/assets/106822f4-40a1-4cc1-857a-8bfe7adcc788)

- Search your bibliography
- Place your cursor over a citation key and get information about the entry
- Automatically format new notes
- Tag completion in `info.yaml` files
- Insert formatted references
- Use an LLM to ask questions about your library (requires the [Papis-ask](https://github.com/jghauser/papis-ask) plugin)

And this is just the beginning! With its fast and always up-to-date sqlite database (courtesy of [sqlite.lua](https://github.com/tami5/sqlite.lua)), a host of [additional features](#planned-features-and-improvements) are just waiting to be implemented. My hope is for this plugin to eventually become Neovim's answer to emacs plugins such as [org-ref](https://github.com/jkitchin/org-ref), [helm-bibtex](https://github.com/tmalsburg/helm-bibtex), and [citar](https://github.com/emacs-citar/citar).

This plugin is in beta and breaking changes are expected. Breaking changes are communicated in a pinned issue and commit messages.

## Features

A number of features (bundled into `modules`) are shipped with papis.nvim. These can be (de)activated as desired.

### *Search* module

![search](https://github.com/user-attachments/assets/bb3f9efa-aef9-49cc-9a9a-4d9171ff6d7a)

Papis.nvim integrates with Telescope and Snacks to easily and quickly search your bibliography. Open the picker and enter the title (or author, year, etc.) of the article you're looking for. Once you've found it, you can insert a citation, open attached files and notes, and edit the `info.yaml` file. When attempting to open a note where none exists, papis.nvim will ask to create a new one.

This module is enabled by default.

<details>
  <summary>Commands and keymaps</summary>

#### Commands:

- `:Papis search`: Open the search picker

#### Default keymaps:

- <leader>pp (normal) / <c-o>p (insert): Open search picker

With the picker open, the following keymaps become available:

- `<cr>` (normal/insert): Insert a reference key (e.g. `@Holland2023OthA`)
- `f` (normal) / `<c-f>` (insert): Open files attached to the entry
- `n` (normal) / `<c-n>` (insert): Open notes attached to the entry (asks for the creation of a new one if none exists)
- `e` (normal) / `c-e` (insert): Open the `info.yaml` file
- `r` (normal) / `c-r` (insert): Insert a formatted full reference (e.g. `Holland (2023). Other - A Black Feminist Consideration of Animal Life.`)

</details>

### *Completion* module

![completion](https://github.com/user-attachments/assets/e2ecc78b-7a49-4db4-89e5-ef8f35a33e58)

When editing `tags` in `info.yaml` files, papis.nvim will suggest tags found in the database. This module is implemented as a [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) or [blink.cmp](https://github.com/Saghen/blink.cmp) source.

This module is enabled by default.

### *At-cursor* module

![at-cursor](https://github.com/user-attachments/assets/c9980e66-f082-4400-93c1-f87583585030)

When the cursor is positioned over a citation key (e.g. `Kant1781Critique`), papis.nvim automatically shows a popup with information about the item and allows interacting with it in various ways.

This module is enabled by default.

<details>
  <summary>Commands and keymaps</summary>

#### Commands:

- `:Papis at-cursor show-popup`: Open a floating window with information about the entry
- `:Papis at-cursor open-file`: Open files attached to the entry
- `:Papis at-cursor open-note`: Open notes attached to the entry (asks for the creation of a new one if none exists)
- `:Papis at-cursor edit`: Open the `info.yaml` file

#### Default keymaps:

- `<leader>pf` (normal): Open file attached to entry under cursor
- `<leader>pe` (normal): Edit the `info.yaml` file of entry under cursor
- `<leader>pn` (normal): Open note attached to entry under cursor
- `<leader>pi` (normal): Show popup with information about entry under cursor

</details>

### *Formatter* module

![formatter](https://github.com/user-attachments/assets/ab8943ca-0574-48b8-b02f-79ab6aad5a46)

When creating new notes (via `:Papis search` or `:Papis at-cursor open-note`), papis.nvim can be set up to format the new note with a custom function. You can, for example, give the note a title that corresponds to the entry's title or provide it with a skeleton structure. Below, in the setup section, there's an example suitable for the `markdown` format.

This module is enabled by default.

### *Ask* module

![ask](https://github.com/user-attachments/assets/f289d9a8-c5dc-46ef-b494-d162e8329bc6)

Ask questions about your library and browse the LLM-generated answers with the picker. This functionality depends on the [Papis-ask](https://github.com/jghauser/papis-ask) plugin.

This module is disabled by default.

<details>
  <summary>Commands and keymaps</summary>

#### Commands:

- `:Papis ask`: Open a picker to ask questions and browse existing answers

You can ask questions with (user-configurable) slash commands, for instance `/ask What is de se thought?`. In addition to `/ask`, papis.nvim by default ships with `/shortask` (limited number of sources), `/longask` (higher number of sources), and `/index` (index new documents).

#### Default keymaps

- <leader>pa (normal) / <c-o>a (insert): Open ask picker

With the picker open, the following keymaps become available:

- `<cr>` (normal/insert): Open a question (or run slash command)
- `d` (normal) / `<c-d>` (insert): Delete an answer

</details>

## The database

All of papis.nvim's features are made possible by a sqlite database that is created when you run `:Papis reload data`. This might take a while, so be patient. From then on, the database is automatically (and very quickly) updated whenever `info.yaml` files are added, changed, or deleted. The database is synchronised when papis.nvim is started and is then kept up-to-date continuously while at least one Neovim instance with a running papis.nvim session exists.

Note that fiddling with the plugin's options can leave the database in a messy state. If strange errors appear, use `:Papis reload data` to re-initialise the database.

## Installation

Note that papis.nvim is only tested with the latest stable version of Neovim. It should work across various OSs, but most development has been done on Linux (do feel free to open issues if you run into trouble on non-Linux systems). An installation of Papis is required.

To run, papis.nvim requires:

- [`yq`](https://github.com/mikefarah/yq). This is used to convert `.yaml` files to `.json` (which can then be read by Neovim). Note that papis.nvim doesn't (currently) support the [python yq](https://github.com/kislyuk/yq).
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

Additionally, may want to install `telescope.nvim` or `snacks.nvim` (for search) and `nvim-cmp` or `blink.cmp` (for completion).

</details>

<details>
  <summary>lazy.nvim</summary>

```lua
{
  "jghauser/papis.nvim",
  dependencies = {
    "kkharji/sqlite.lua",
    "MunifTanjim/nui.nvim",
    -- If not already installed, you may also want one of:
    -- "hrsh7th/nvim-cmp",
    -- "saghen/blink.cmp",

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
    -- If not already installed, you may also want one of:
    -- "hrsh7th/nvim-cmp",
    -- "saghen/blink.cmp",

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
                # if not already installed, you may also want one of:
                # nvim-cmp",
                # blink-cmp,

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

  -- You can enable disabled modules (e.g. the 'ask' module) like so:
  -- ["ask"] = {
  --   enable = true,
  -- },
})
```

<details>
  <summary>All configuration options (with defaults)</summary>

```lua
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
  related_to = "luatable",
},

-- Path to the papis.nvim database.
db_path = vim.fn.stdpath("data") .. "/papis/papis-nvim.sqlite3",

-- Name of the `yq` executable.
yq_bin = "yq",

-- Base papis command (can for example be used to change the config file used).
papis_cmd_base = { "papis" },

-- Filetypes that start papis.nvim.
init_filetypes = { "markdown", "norg", "yaml", "typst" },

-- Papis options to import into papis.nvim.
papis_conf_keys = { "info-name", "notes-name", "dir", "opentool" },

-- Whether to enable pretty icons (requires something like Nerd Fonts)
enable_icons = true,

-- Configuration of the search module.
["search"] = {

  -- Whether to enable this module.
  enable = true,

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
  -- An element may also just contain `empty_line`. This is used to insert an empty line.
  -- Strings that define the formatting (such as in 2. and 4. above) can optionally
  -- be a table mapping strings onto tables that define first, an icon, and second, a
  -- non-icon version. So, a field `some_string = { "󱀁  ", "%s: " }` would mean that if
  -- the value is `some_string` it will get replaced with the defined icon (or non-icon
  -- version). The special key `fallback` is used to define how to handle strings that
  -- aren't explicitly configured. The `enable_icons` option determines whether the
  -- icon or non-icon version is used.
  preview_format = {
    { "author", "%s", "PapisPreviewAuthor" },
    { "year", "%s", "PapisPreviewYear" },
    { "title", "%s", "PapisPreviewTitle" },
    { "empty_line" },
    { "journal", "%s", "PapisPreviewValue", "show_key", { fallback = { "󱀁  ", "%s: " } }, "PapisPreviewKey" },
    { "type", "%s", "PapisPreviewValue", "show_key", { fallback = { "󰀼  ", "%s: " } }, "PapisPreviewKey" },
    { "ref", "%s", "PapisPreviewValue", "show_key", { fallback = { "󰌋  ", "%s: " } }, "PapisPreviewKey" },
    { "tags", "%s", "PapisPreviewValue", "show_key", { fallback = { "󰓹  ", "%s: " } }, "PapisPreviewKey" },
    { "abstract", "%s", "PapisPreviewValue", "show_key", { fallback = { "󰭷  ", "%s: " } }, "PapisPreviewKey" },
  },

  -- The format of each line in the the results window. Here, everything is show on
  -- one line (otherwise equivalent to points 1-3 of `preview_format`). The `force_space`
  -- value is used to force whitespace for icons (so that if e.g. a file is absent, it will
  -- show "  ", ensuring that columns are aligned.)
  results_format = {
    { "files", { fallback = { "󰈙 ", "F " } }, "PapisResultsFiles", "force_space" },
    { "notes", { fallback = { "󰆈 ", "N " } }, "PapisResultsNotes", "force_space" },
    { "author", "%s ", "PapisResultsAuthor" },
    { "year", "(%s) ", "PapisResultsYear" },
    { "title", "%s", "PapisResultsTitle" },
  },
},

-- Configuration of the completion module.
["completion"] = {

  -- Whether to enable this module.
  enable = true,

  -- Set the completion provider.
  provider = "auto", ---@type "auto" | "cmp" | "blink"
},

-- Configuration of the at-cursor module.
["at-cursor"] = {

  -- Whether to enable this module.
  enable = true,

  -- The format of the popup shown on `:Papis at-cursor show-popup` (equivalent to points 1-3
  -- of `preview_format`). Note that one of the lines is composed of multiple elements. Note
  -- also the `{ "vspace", "vspace" },` line which is exclusive to `popup_format` and which tells
  -- papis.nvim to fill the space between the previous and next element with whitespace (and
  -- in effect make whatever comes after right-aligned). It can only occur once in a line.
  popup_format = {
    {
      { "author", "%s", "PapisPopupAuthor" },
      { "vspace", "vspace" },
      { "files", { fallback = { "󰈙 ", "F " } }, "PapisResultsFiles" },
      { "notes", { fallback = { "󰆈 ", "N " } }, "PapisResultsNotes" },
    },
    { "year",  "%s", "PapisPopupYear" },
    { "title", "%s", "PapisPopupTitle" },
  },

  -- Configuration of the popup that automatically appears when the cursor is on a `ref` in normal mode
    auto_popup = {

      -- Whether to automatically show the popup
      enable = true,

      -- The delay (in ms) after which to show the popup after the cursor has been moved to it
      delay = 1000,
    }
},

-- Configuration of formatter module.
["formatter"] = {

  -- Whether to enable this module.
  enable = true,

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

-- Configuration of the at-cursor module.
["ask"] = {

  -- Whether to enable this module.
  enable = false,

  -- Picker provider
  provider = "auto", ---@type "auto" | "snacks" | "telescope"

  -- Defines the arguments for available slash commands (they get added to `papis_cmd_base`).
  -- You can call them with e.g. `/ask`. The {input} value gets replaced with the your input
  -- (e.g. /ask MY INPUT).
  slash_command_args = {
    ask = { "ask", "--output", "json", "{input}" },
    shortask = { "ask", "--output", "json", "--evidence-k", "5", "--max-sources", "3", "{input}" },
    longask = { "ask", "--output", "json", "--evidence-k", "20", "--max-sources", "10", "{input}" },
    index = { "ask", "index" },
  },

  -- Whether to initially sort entries by time-added.
  initial_sort_by_time_added = true,

  -- Picker keymaps
  picker_keymaps = {
    ["<CR>"] = { "open_answer", mode = { "n", "i" }, desc = "(Papis) Open answer" },
    ["d"] = { "delete_answer", mode = "n", desc = "(Papis) Delete answer" },
    ["<c-d>"] = { "delete_answer", mode = "i", desc = "(Papis) Delete answer" },
  },

  -- The format of the picker preview (see above for details).
  preview_format = {
    { "question", "%s", "PapisPreviewQuestion", "show_key", { fallback = { "󰍉  ", "Question: " } }, "PapisPreviewKey" },
    { "empty_line" },
    { "answer", "%s", "PapisPreviewAnswer", "show_key", { fallback = { "󱆀  ", "Answer: " } }, "PapisPreviewKey" },
  },

  -- The format of each line in the the picker results (see above for details).
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

-- Configurations relevant for parsing `info.yaml` files.
["papis-storage"] = {

  -- Whether to enable this module.
  enable = true,

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

-- Configuration of custom HL groups
["colors"] = {

  -- Whether to enable this module.
  enable = true,
},

-- Configuration of the debug module
["debug"] = {

  -- Whether to enable this module.
  enable = false,
},
```

</details>

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

## Usage

Papis.nvim will start automatically according to the filetypes defined in `init_filetypes` (see the [setup section](#setup)). When first starting, papis.nvim will import some configuration values from Papis and save them in the database. It will then prompt you to run `:Papis reload data` to import all of your library into the database. If you update your Papis configuration, you should re-import the configuration into papis.nvim with `:Papis reload config` and run `:Papis reload data` again.

## Highlight Groups

Papis.nvim defines and links a number of default highlight groups. In order to change the colours, simply override them with whatever you desire.

<details>
  <summary>Highlight groups</summary>

- `PapisPreviewAuthor`: The author field in the picker previewer
- `PapisPreviewYear`: The year field in the picker previewer
- `PapisPreviewTitle`: The title field in the picker previewer
- `PapisPreviewKey`: The keys in the picker previewer (when set with `show_key`, see the setup section)
- `PapisPreviewValue`: The values in the picker previewer (when set with `show_key`, see the setup section)
- `PapisPreviewQuestion`: The answer in the picker previewer
- `PapisPreviewAnswer`: The answer in the picker previewer
- `PapisResultsAuthor`: The author in the picker results window
- `PapisResultsYear`: The year in the picker results window
- `PapisResultsTitle`: The title in the picker results window
- `PapisResultsFiles`: The files in the picker results window
- `PapisResultsNotes`: The notes in the picker results window
- `PapisResultsQuestion`: The question in the picker results window
- `PapisResultsTimeAdded`: The time_added in the picker results window
- `PapisResultsCommand`: The slash command in the picker results window
- `PapisPopupAuthor`: The author in the cursor action popup
- `PapisPopupYear`: The year in the cursor action popup
- `PapisPopupTitle`: The title in the cursor action popup

</details>

## Issues/Troubleshooting

You can use `:checkhealth papis` for some basic troubleshooting. Make sure to open a file of a type configured in `init_filetypes` before calling `checkhealth`, so that papis.nvim is properly loaded. In addition, you can enable the `debug` module, which exposes the following commands and a log:

- `:Papis debug info`: Get the path to the log file
- `:Papis debug stop-watchers`: Stops file watching for the current Neovim instance. Helps if you want to use one particular instance to try things out, but have other Neovim instances open on the system.
- `:Papis debug start-watchers`: Starts file watching for the current Neovim instance

Please open an issue when you find bugs!

## Contributing

I'm more than happy about any contributions, ideas for improvements, ideas for new features, bug reports, and so on. If you have a cool idea for a new functionality you want to implement, I'd be happy to guide you through the process of creating a new module.

## Thanks

Big thanks to [Irteza Rehman](https://www.irtezarehman.com/) for generously contributing the beautiful logo.
