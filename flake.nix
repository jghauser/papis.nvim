{
  description = "Papis.nvim development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
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
    overlays.default = final: prev: {
      vimPlugins = prev.vimPlugins.extend (f: p: {
        papis-nvim = final.vimUtils.buildVimPlugin {
          pname = "papis.nvim";
          version = toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown");
          src = self;
          dependencies = [
            f.telescope-nvim
            f.sqlite-lua
            f.plenary-nvim
            f.nui-nvim
            f.nvim-treesitter
            f.nvim-treesitter-grammar-yaml
            final.yq-go
          ];
        };
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
            pkgs.sqlitebrowser
            pkgs.yq-go
            run-tests
            run-test
            run-app
          ];
        };
      });
  };
}
