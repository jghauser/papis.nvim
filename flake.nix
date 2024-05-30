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
            pkgs.vimPlugins.nvim-treesitter
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
            run-tests = pkgs.writeShellApplication {
              name = "run-tests";
              text =
                # bash
                ''
                  # nvim --headless -u tools/minimal_init.lua -c "PlenaryBustedDirectory tests/spec"
                  find tests/spec -type f -exec nvim --headless -u tools/minimal_init.lua -c "PlenaryBustedFile {}" \;
                '';
            };

            run-test = pkgs.writeShellApplication {
              name = "run-test";
              text =
                # bash
                ''
                  nvim --headless -u tools/minimal_init.lua -c "PlenaryBustedFile $1" \;
                '';
            };

            run-app = pkgs.writeShellApplication {
              name = "run-app";
              text =
                # bash
                ''
                  nvim -u tools/minimal_init.lua -c "lua _Load_papis()" -c "e test.md"
                '';
            };
          in [
            self.packages.${system}.papis-nvim
            pkgs.sqlitebrowser
            pkgs.yq-go
            pkgs.vimPlugins.nvim-nio
            run-tests
            run-test
            run-app
          ];
        };
      });
  };
}
