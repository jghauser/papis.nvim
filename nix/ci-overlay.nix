{
  self,
  name,
}:
final: prev:
let
  mkNvimMinimal =
    nvim:
    with final;
    let
      neovimConfig = neovimUtils.makeNeovimConfig {
        withPython3 = false;
        viAlias = true;
        vimAlias = true;
        extraLuaPackages = luaPkgs: [
          luaPkgs.papis-nvim
        ];
        plugins = with vimPlugins; [
          # Completion engines
          nvim-cmp
          blink-cmp

          # Pickers
          telescope-nvim
          snacks-nvim

          # Base plugins
          (nvim-treesitter.withPlugins (ps: with ps; [ tree-sitter-yaml ]))
        ];
      };

      luaConfig =
        # lua
        ''
          lua << EOF
          local o = vim.o
          local cmd = vim.cmd
          local fn = vim.fn

          -- disable swap
          o.swapfile = false

          -- add current directory to runtimepath
          vim.opt.runtimepath:prepend(vim.fn.getcwd())

          -- Read configuration from environment
          local completion_provider = os.getenv("PAPIS_TEST_COMPLETION")
          local search_provider = os.getenv("PAPIS_TEST_SEARCH")
          local load_papis = os.getenv("PAPIS_TEST_LOAD_PAPIS")

          -- Completion setup
          if completion_provider == "cmp" then
            local cmp = require("cmp")
            cmp.setup({
              mapping = cmp.mapping.preset.insert({
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<C-e>"] = cmp.mapping.abort(),
                ["<CR>"] = cmp.mapping.confirm({ select = true }),
              }),
              sources = cmp.config.sources({
                { name = "papis" },
              }),
            })
          elseif completion_provider == "blink" then
            local blink = require("blink.cmp")
            blink.setup({
              sources = {
                per_filetype = {
                  yaml = { "papis" }
                },
              },
            })
          end

          -- Picker setup
          if search_provider == "telescope" then
            local telescope = require("telescope")
            telescope.setup({
              defaults = {
                layout_strategy = "vertical",
              },
            })
          elseif search_provider == "snacks" then
            require("snacks").setup({
              picker = {},
            })
          end

          -- remap leader
          vim.g.mapleader = " "

          ---Sets up papis
          if load_papis then
            local db_path = vim.fn.stdpath("cache") .. "/papis_db/papis-nvim-test.sqlite3"

            local default_config = {
              enable_modules = {
                ["debug"] = true,
                ["testing"] = true,
              },
              enable_keymaps = true,
              db_path = db_path,
              ["search"] = {
                provider = search_provider,
              },
              ["completion"] = {
                provider = completion_provider
              },
            }
            local init_result = require("papis").setup(default_config)

            return init_result
          end
          EOF
        '';

      runtimeDeps = [ yq-go ];
    in
    final.wrapNeovimUnstable nvim (
      neovimConfig
      // {
        wrapperArgs =
          lib.escapeShellArgs neovimConfig.wrapperArgs
          + " "
          + ''--set NVIM_APPNAME "nvim-${name}"''
          + " "
          + ''--prefix PATH : "${lib.makeBinPath runtimeDeps}"'';
        wrapRc = true;
        neovimRcContent = luaConfig;
      }
    );
in
{
  neovim-with-plugin = mkNvimMinimal final.neovim-unwrapped;
}
