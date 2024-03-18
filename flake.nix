{
  description = "Papis.nvim development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];
    forAllSystems = f:
      builtins.listToAttrs (map (name: {
          inherit name;
          value = f name;
        })
        systems);
  in {
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
