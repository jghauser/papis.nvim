{
  description = "Papis.nvim flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      ...
    }:
    let
      name = "papis.nvim";

      plugin-overlay = import ./nix/plugin-overlay.nix {
        inherit name self;
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          system,
          ...
        }:
        let
          ci-overlay = import ./nix/ci-overlay.nix {
            inherit self name;
          };

          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              plugin-overlay
              ci-overlay
            ];
          };

          devShell = pkgs.mkShell {
            buildInputs =
              let
                nvim-test = import ./nix/nvim-test.nix { inherit pkgs; };
              in
              [
                pkgs.sqlitebrowser
                pkgs.yq-go
                pkgs.luajit
                nvim-test
              ];
          };
        in
        {
          devShells = {
            default = devShell;
            inherit devShell;
          };

          packages = rec {
            default = papis-nvim;
            inherit (pkgs.luajitPackages) papis-nvim;
            inherit (pkgs) neovim-with-plugin;
          };
        };
      flake = {
        overlays.default = plugin-overlay;
      };
    };
}
