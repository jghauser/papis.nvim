# Add flake.nix test inputs as arguments here
{
  self,
  name,
}: final: prev: let
  mkNvimMinimal = nvim:
    with final; let
      profile-nvim = pkgs.vimUtils.buildVimPlugin {
        name = "profile.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "stevearc";
          repo = "profile.nvim";
          rev = "0ee32b7aba31d84b0ca76aaff2ffcb11f8f5449f";
          hash = "sha256-usyy1kST8hq/3j0sp7Tpf/1mld6RtcVABPo/ygeqzbU=";
        };
      };

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
          profile-nvim
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

              -- disable swap
              o.swapfile = false

              -- add current directory to runtimepath to have papis.nvim
              -- be loaded from the current directory
              vim.opt.runtimepath:prepend(vim.fn.getcwd())

              -- profile.nvim
              local should_profile = os.getenv("NVIM_PROFILE")
              if should_profile then
                require("profile").instrument_autocmds()
                if should_profile:lower():match("^start") then
                  require("profile").start("*papis")
                else
                  require("profile").instrument("*")
                end
              end
              local function toggle_profile()
                local prof = require("profile")
                if prof.is_recording() then
                  prof.stop()
                  vim.ui.input({ prompt = "Save profile to:", completion = "file", default = "profile.json" }, function(filename)
                    if filename then
                      prof.export(filename)
                      vim.notify(string.format("Wrote %s", filename))
                    end
                  end)
                else
                  vim.notify("Starting profiling")
                  prof.start("*papis")
                end
              end
              vim.keymap.set("", "<f1>", toggle_profile)

              -- cmp
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
                  { name = "papis" },
                }),
              })

              -- telescope
              local telescope = require("telescope")
              telescope.setup({
                defaults = {
                  -- so that I can see the preview even with a split screen
                  layout_strategy = "vertical",
                },
              })

              -- remap leader
              vim.g.mapleader = " "

              ---Sets up papis
              ---@param opts table? Custom configuration options
              ---@param rm_db boolean? Remove db on startup (defaults to `true`)
              function _Load_papis(opts, rm_db)
                local db_path = vim.fn.stdpath("cache") .. "/papis_db/papis-nvim-test.sqlite3"
                local default_config = {
                  enable_modules = {
                    ["debug"] = true,
                    ["testing"] = true,
                  },
                  enable_keymaps = true,
                  db_path = db_path,
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
