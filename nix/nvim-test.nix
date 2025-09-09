{ pkgs }:

pkgs.writeShellApplication {
  name = "nvim-test";
  text =
    let
      test-lib-dir = "~/.cache/papis_test_library";
    in
    # bash
    ''
      # Default values
      COMPLETION_PROVIDER="blink"
      PICKER_PROVIDER="snacks"
      LOAD_PAPIS=true
      RM_DB=false

      # Parse command line arguments
      while [[ $# -gt 0 ]]; do
        case $1 in
          --completion|-c)
            COMPLETION_PROVIDER="$2"
            shift 2
            ;;
          --picker|-p)
            PICKER_PROVIDER="$2"
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
            echo "  -p, --picker ENGINE        Picker engine (telescope, snacks)"
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

      case "$PICKER_PROVIDER" in
        telescope|snacks) ;;
        *)
          echo "Invalid picker engine: $PICKER_PROVIDER"
          echo "Valid options: telescope, snacks"
          exit 1
          ;;
      esac

      echo "Using completion engine: $COMPLETION_PROVIDER"
      echo "Using picker engine: $PICKER_PROVIDER"
      echo "Loading papis.nvim: $LOAD_PAPIS"

      if [ "$RM_DB" = true ]; then
        echo "Removing papis.nvim database..."
        ${pkgs.coreutils}/bin/rm -f ~/.cache/nvim-papis.nvim/papis_db/papis-nvim-test.sqlite3
      fi

      # Set up test environment
      ${pkgs.coreutils}/bin/rm -rf ${test-lib-dir}
      ${pkgs.coreutils}/bin/cp -r ./spec/resources/library ${test-lib-dir}

      # Export configuration as environment variables
      export PAPIS_TEST_COMPLETION_PROVIDER="$COMPLETION_PROVIDER"
      export PAPIS_TEST_PICKER_PROVIDER="$PICKER_PROVIDER"
      export PAPIS_TEST_LOAD_PAPIS="$LOAD_PAPIS"

      echo "Starting Neovim..."
      ${pkgs.neovim-with-plugin}/bin/nvim -c "e test.md"
    '';
}
