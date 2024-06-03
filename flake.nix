{
  description = "Papis.nvim development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    systems = ["x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = f:
      builtins.listToAttrs (map (name: {
          inherit name;
          value = f name;
        })
        systems);
  in {
    packages =
      forAllSystems
      (system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        papis-nvim = pkgs.vimUtils.buildVimPlugin {
          pname = "papis.nvim";
          version = toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown");
          src = self;
          dependencies = [
            pkgs.vimPlugins.telescope-nvim
            pkgs.vimPlugins.sqlite-lua
            pkgs.vimPlugins.plenary-nvim
            pkgs.vimPlugins.nui-nvim
            pkgs.vimPlugins.nvim-treesitter-parsers.yaml
          ];
        };
      });

    overlays.default = final: prev: {
      vimPlugins = prev.vimPlugins.extend (f: p: {
        papis-nvim = self.packages.${final.system}.papis-nvim;
      });
    };
    devShells =
      forAllSystems
      (system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        default = pkgs.mkShell {
          buildInputs = let
            custom-nvim = pkgs.neovim.override {
              configure = {
                customRC = ''
                  luafile ./tests/minimal_init.lua
                '';
                packages.myVimPackage.start =
                  self.packages.${system}.papis-nvim.dependencies
                  ++ [
                    pkgs.vimPlugins.nvim-cmp
                  ];
              };
            };

            nvim-test = pkgs.writeShellApplication {
              name = "nvim-test";
              text =
                # bash
                ''
                  ${custom-nvim}/bin/nvim -c "lua _Load_papis()" -c "e test.md"
                '';
            };
          in [
            pkgs.sqlitebrowser
            pkgs.yq-go
            pkgs.luajit
            nvim-test
          ];
        };
      });
  };
}
