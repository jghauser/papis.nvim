{
  description = "Papis.nvim development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, devenv, ... } @ inputs:
    let
      systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) systems);
    in
    {
      devShells = forAllSystems
        (system:
          let
            pkgs = import nixpkgs {
              inherit system;
            };
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  languages.lua = {
                    enable = true;
                    package = pkgs.luajit;
                  };
                  scripts.run-tests.exec = ''
                    # nvim --headless -u tests/minimal_init.lua -c 'PlenaryBustedDirectory tests/spec'
                    find tests/spec -type f -exec nvim --headless -u tests/minimal_init.lua -c 'PlenaryBustedFile {}' \;
                  '';
                  scripts.run-app.exec = ''
                    nvim -u tests/minimal_init.lua -c 'lua __load_papis()'
                  '';
                }
              ];
            };
          });
    };
}
