{
  nushell-nightly,
  monurepo,
  nu-batteries,
  ...
}:
{
  universal =
    {
      lib,
      pkgs,
      nixosConfig,
      ...
    }:
    let
      inherit (lib.ns.nushell) mkNushellInline;
    in
    {

      nixpkgs.overlays = [ nushell-nightly.overlays.default ];
      nix.settings.substituters = [ "https://nushell-nightly.cachix.org" ];
      nix.settings.trusted-public-keys = [
        "nushell-nightly.cachix.org-1:nLwXJzwwVmQ+fLKD6aH6rWDoTC73ry1ahMX9lU87nrc="
      ];

      users.users.arakhor.shell = nixosConfig.programs.nushell.finalPackage;

      programs.nushell = {
        enable = true;

        environmentVariables = {
          ENV_CONVERSIONS =
            let
              converterBySeparator = char: {
                from_string = mkNushellInline "{|s| $s | split row ${char} }";
                to_string = mkNushellInline "{|v| $v | str join ${char} }";
              };
              esepListConverter = converterBySeparator "(char esep)";
              spaceListConverter = converterBySeparator "(char space)";
            in
            {
              DIRS_LIST = esepListConverter;
              GIO_EXTRA_MODULES = esepListConverter;
              GTK_PATH = esepListConverter;
              INFOPATH = esepListConverter;
              LIBEXEC_PATH = esepListConverter;
              LS_COLORS = esepListConverter;
              PATH = esepListConverter;
              QTWEBKIT_PLUGIN_PATH = esepListConverter;
              SESSION_MANAGER = esepListConverter;
              TERMINFO_DIRS = esepListConverter;
              XCURSOR_PATH = esepListConverter;
              XDG_CONFIG_DIRS = esepListConverter;
              XDG_DATA_DIRS = esepListConverter;

              NIX_PROFILES = spaceListConverter;
            };
        };

        settings = {
          show_banner = false;
          edit_mode = "vi";
          cursor_shape = {
            vi_insert = "line";
            vi_normal = "block";
          };
          use_kitty_protocol = true;

          display_errors = {
            exit_code = false;
            termination_signal = true;
          };

          filesize = {
            show_unit = true;
            unit = "metric";
          };

          history = {
            file_format = "sqlite";
            isolation = true;
            max_size = 100000;
            sync_on_enter = true;
          };

          table = {
            footer_inheritance = false;
            header_on_separator = true;
            index_mode = "auto";
            missing_value_symbol = "󰟢";
            mode = "rounded";
            show_empty = true;
            trim = {
              methodology = "wrapping";
              wrapping_try_keep_words = true;
            };
          };

          keybindings = [
            {
              name = "cut_line_to_end";
              event.edit = "cuttoend";
              keycode = "char_k";
              mode = [
                "emacs"
                "vi_insert"
              ];
              modifier = "control";
            }

            {
              name = "cut_line_from_start";
              modifier = "control";
              keycode = "char_u";
              event.edit = "cutfromstart";
              mode = [
                "emacs"
                "vi_insert"
              ];
            }

            {
              name = "completion_menu_next";
              modifier = "control";
              keycode = "char_n";
              event.until = [
                {
                  name = "completion_menu";
                  send = "menu";
                }
                { send = "menunext"; }
                { edit = "complete"; }
              ];
              mode = [
                "emacs"
                "vi_normal"
                "vi_insert"
              ];
            }

            {
              name = "completion_menu_prev";
              modifier = "control";
              keycode = "char_p";
              event.until = [
                {
                  name = "completion_menu";
                  send = "menu";
                }
                { send = "menuprevious"; }
                { edit = "complete"; }
              ];
              mode = [
                "emacs"
                "vi_normal"
                "vi_insert"
              ];
            }

            {
              name = "completion_menu_complete";
              modifier = "control";
              keycode = "char_y";
              event.send = "Enter";
              mode = [
                "emacs"
                "vi_normal"
                "vi_insert"
              ];
            }

            {
              name = "job_unfreeze";
              modifier = "control";
              keycode = "char_z";
              event = {
                send = "executehostcommand";
                cmd = "fg";
              };
              mode = [
                "emacs"
                "vi_normal"
                "vi_insert"
              ];
            }
          ];
        };

        experimentalOptions = [
          "pipefail"
          "enforce-runtime-annotations"
        ];

        plugins = with pkgs.nushellPlugins; [
          formats
          gstat
          query
          polars
        ];

        libraries = [
          "${pkgs.nu_scripts}/share/nu_scripts"
          nu-batteries
          monurepo
        ];

        shellAliases = {
          fg = "job unfreeze";
        };

        shellInit = # nu
          ''
            source /home/arakhor/configuration/nushell/theme.nu
            # Setup completions on non-interactive shells for use with nu-lsp
            def nix-completer [spans: list<string>] {
              let current_arg = $spans | length| $in - 1
              with-env { NIX_GET_COMPLETIONS: $current_arg } { $spans| skip 1| ^nix ...$in }
              | lines
              | skip 1
              | parse "{value}\t{description}"
            }

            @complete nix-completer
            extern nix []

            def carapace-completer [spans: list<string>] {
              carapace $spans.0 nushell ...$spans
              | from json
              | if ($in | default [] | where value =~ $"($spans | last)ERR_?" | is-empty) { $in } else { null }
            }

            let external_completer = {|spans: list<string>|
              carapace-completer $spans
              # avoid empty result preventing native file completion
              | default --empty null
            }

            $env.config.completions.case_sensitive = false
            $env.config.completions.quick = true
            $env.config.completions.partial = true
            $env.config.completions.algorithm = "prefix" # prefix or fuzzy
            $env.config.completions.external.completer = $external_completer
          '';

        interactiveShellInit =
          let
            nix = lib.getExe nixosConfig.nix.package;
            nixfmt = lib.getExe pkgs.nixfmt-rfc-style;
          in
          # nu
          ''
            # Parse text as nix expression
            def "from nix" []: string -> any {
                ${nix} eval --json -f - | from json 
            }

            # Convert table data into a nix expression
            def "to nix" [
                --raw(-r) # don't format the result
                --indent(-i):int = 4 # specify indentation width
            ]: any -> string {
                to json --raw
                | str replace --all "''$" $"(char single_quote)(char single_quote)$"
                | ${nix} eval --expr $"builtins.fromJSON '''($in)'''"
                | if not $raw { ${nixfmt} - $"--indent=($indent)" } else { $in }
                | collect
                | metadata set --content-type "application/nix" 
            }
          '';
      };

      preserveHome = {
        files = [
          ".config/nushell/history.sqlite3"
          ".config/nushell/history.sqlite3-shm"
          ".config/nushell/history.sqlite3-wal"
        ];
        directories = [
          ".cache/nushell"
          ".local/share/nushell"
        ];
      };
    };
}
