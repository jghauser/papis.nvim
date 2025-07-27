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
                nvim-test = pkgs.writeShellApplication {
                  name = "nvim-test";
                  text =
                    let
                      test-lib-dir = "~/.cache/papis_test_library";
                    in
                    # bash
                    ''
                      # Default values
                      COMPLETION_PROVIDER="blink"
                      SEARCH_PROVIDER="snacks"
                      LOAD_PAPIS=true
                      RM_DB=false

                      # Parse command line arguments
                      while [[ $# -gt 0 ]]; do
                        case $1 in
                          --completion|-c)
                            COMPLETION_PROVIDER="$2"
                            shift 2
                            ;;
                          --search|-s)
                            SEARCH_PROVIDER="$2"
                            shift 2
                            ;;
                          --no-papis|-n)
                            LOAD_PAPIS=false
                            shift 1
                            ;;
                          --rm-db|-r)
                            RM_DB=true
                            shift 1
                            ;;
                          --help|-h)
                            echo "Usage: nvim-test [options]"
                            echo "Options:"
                            echo "  -c, --completion ENGINE    Completion engine (cmp, blink)"
                            echo "  -s, --search ENGINE        Picker engine (telescope, snacks)"
                            echo "  -n, --no-papis             Do not load papis.nvim"
                            echo "  -r, --rm-db                Clear the papis.nvim db before start"
                            echo "  -h, --help                 Show this help"
                            exit 0
                            ;;
                          *)
                            echo "Unknown option: $1"
                            echo "Use --help for usage information"
                            exit 1
                            ;;
                        esac
                      done

                      # Validate engines
                      case "$COMPLETION_PROVIDER" in
                        cmp|blink) ;;
                        *)
                          echo "Invalid completion engine: $COMPLETION_PROVIDER"
                          echo "Valid options: cmp, blink"
                          exit 1
                          ;;
                      esac

                      case "$SEARCH_PROVIDER" in
                        telescope|snacks) ;;
                        *)
                          echo "Invalid picker engine: $SEARCH_PROVIDER"
                          echo "Valid options: telescope, snacks"
                          exit 1
                          ;;
                      esac

                      echo "Using completion engine: $COMPLETION_PROVIDER"
                      echo "Using picker engine: $SEARCH_PROVIDER"
                      echo "Loading papis.nvim: $LOAD_PAPIS"

                      if [ "$RM_DB" = true ]; then
                        echo "Removing papis.nvim database..."
                        ${pkgs.coreutils}/bin/rm -f ~/.cache/nvim-papis.nvim/papis_db/papis-nvim-test.sqlite3
                      fi

                      # Set up test environment
                      ${pkgs.coreutils}/bin/rm -rf ${test-lib-dir}
                      ${pkgs.coreutils}/bin/cp -r ./tests/files/library ${test-lib-dir}

                      # Export configuration as environment variables
                      export PAPIS_TEST_COMPLETION="$COMPLETION_PROVIDER"
                      export PAPIS_TEST_SEARCH="$SEARCH_PROVIDER"
                      export PAPIS_TEST_LOAD_PAPIS="$LOAD_PAPIS"

                      echo "Starting Neovim..."
                      ${pkgs.neovim-with-plugin}/bin/nvim -c "e test.md"
                    '';
                };
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
