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
          local completion_provider = os.getenv("PAPIS_TEST_COMPLETION_PROVIDER")
          local picker_provider = os.getenv("PAPIS_TEST_PICKER_PROVIDER")
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
          if picker_provider == "telescope" then
            local telescope = require("telescope")
            telescope.setup({
              defaults = {
                layout_strategy = "vertical",
              },
            })
          elseif picker_provider == "snacks" then
            require("snacks").setup({
              picker = {},
            })
          end

          -- remap leader
          vim.g.mapleader = " "

          ---Sets up papis
          if load_papis then
            local default_config = {
              papis_cmd_base = { "papis", "-c", "./tests/papis_config" },
              enable_keymaps = true,
              ["search"] = {
                provider = picker_provider,
              },
              ["completion"] = {
                provider = completion_provider
              },
              ["ask"] = {
                enable = true,
                provider = picker_provider,
              },
              ["debug"] = {
                enable = true,
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
