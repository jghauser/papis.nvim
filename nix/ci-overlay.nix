# Add flake.nix test inputs as arguments here
{
  self,
  name,
}: final: prev: let
  mkNvimMinimal = nvim:
    with final; let
      neovimConfig = neovimUtils.makeNeovimConfig {
        withPython3 = true;
        viAlias = true;
        vimAlias = true;
        extraLuaPackages = luaPkgs: [
          luaPkgs.papis-nvim
        ];
        plugins = with vimPlugins; [
          telescope-nvim
          nvim-cmp
          (nvim-treesitter.withPlugins (ps:
            with ps; [
              tree-sitter-yaml
            ]))
        ];
      };
      runtimeDeps = [
        yq-go
      ];
    in
      final.wrapNeovimUnstable nvim (neovimConfig
        // {
          wrapperArgs =
            lib.escapeShellArgs neovimConfig.wrapperArgs
            + " "
            + ''--set NVIM_APPNAME "nvim-papis"''
            + " "
            + ''--prefix PATH : "${lib.makeBinPath runtimeDeps}"'';
          wrapRc = true;
          neovimRcContent =
            # lua
            ''
              lua << EOF
              local o = vim.o
              local cmd = vim.cmd
              local fn = vim.fn

              o.termguicolors = true
              o.swapfile = false

              vim.opt.runtimepath:prepend(vim.fn.getcwd())

              -- setup dependencies
              local cmp = require("cmp")
              cmp.setup({
                mapping = cmp.mapping.preset.insert({
                  ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                  ["<C-f>"] = cmp.mapping.scroll_docs(4),
                  ["<C-Space>"] = cmp.mapping.complete(),
                  ["<C-e>"] = cmp.mapping.abort(),
                  ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
                }),
                sources = cmp.config.sources({
                  -- your other source
                  { name = "papis" },
                }),
              })

              -- remap leader
              vim.g.mapleader = " "

              ---Sets up papis
              ---@param opts table? Custom configuration options
              ---@param autostart? boolean? Enable autostart (defaults to `true`)
              ---@param rm_db? boolean? Delete db (defaults to `false`)
              function _Load_papis(opts, rm_db)
                local db_path = vim.fn.stdpath("cache") .. "/papis_db/papis-nvim-test.sqlite3"
                local default_config = {
                  enable_modules = {
                    ["debug"] = true,
                    ["testing"] = true,
                  },
                  enable_keymaps = true,
                  db_path = vim.fn.stdpath("cache") .. "/papis_db/papis-nvim-test.sqlite3",
                }
                local new_config = vim.tbl_deep_extend("force", default_config, opts or {})
                local init_result = require("papis").setup(new_config)

                -- remove previous db
                if rm_db then
                  os.remove(db_path)
                end

                return init_result
              end
              EOF
            '';
        });
in {
  neovim-with-papis = mkNvimMinimal final.neovim-unwrapped;
}
