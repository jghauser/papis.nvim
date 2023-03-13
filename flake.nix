{
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
                  # https://devenv.sh/reference/options/
                  languages.lua = {
                    enable = true;
                    package = pkgs.luajit;
                  };
                  scripts.run-tests.exec = ''
                    ${pkgs.neovim}/bin/nvim --headless -u tests/minimal_init.lua -c 'PlenaryBustedDirectory tests/spec'
                  '';
                  scripts.run-app.exec = ''
                    ${pkgs.neovim}/bin/nvim -u tests/minimal_init.lua -c 'lua __load_papis()'
                  '';
                  # packages = [ pkgs.hello ];
                  #
                  # enterShell = ''
                  #   hello
                  # '';
                }
              ];
            };
          });
    };
}
