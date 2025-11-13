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
        {
            imports = [
                #
                # SECTION: My actual configuration
                #
                {
                    programs.nushell = {
                        experimentalOptions = [ "pipefail" ];
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
                            eza = "eza --long --all --icons --time-style long-iso";
                        };
                        shellInit = # nu
                            ''
                                # Visual configuration is sourced on every shell,
                                # so that the output of scripts looks same as in repl
                                source ${nixosConfig.programs.nh.flake}/nushell/theme.nu
                                $env.LS_COLORS = (${lib.getExe pkgs.vivid} generate tokyonight-night)

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

                        interactiveShellInit = # nu
                            ''
                                # Parse text as nix expression
                                def "from nix" []: string -> any {
                                    ${lib.getExe pkgs.lix} eval --json -f - | from json
                                }

                                # Convert table data into a nix expression
                                def "to nix" [
                                    --format(-f) # Format the result
                                ]: any -> string {
                                    to json --raw
                                    | str replace --all "''$" $"(char single_quote)(char single_quote)$"
                                    | nix eval --expr $"builtins.fromJSON '''($in)'''"
                                    | if $format { ${lib.getExe pkgs.nixfmt-rfc-style} - | ${lib.getExe pkgs.bat} --paging=never --style=plain -l nix } else { $in }
                                }

                                source ${nixosConfig.programs.nh.flake}/nushell/config.nu
                            '';
                    };

                    users.defaultUserShell = nixosConfig.programs.nushell.finalPackage;

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

                    nixpkgs.overlays = [ nushell-nightly.overlays.default ];
                    nix.settings = {
                        substituters = [ "https://nushell-nightly.cachix.org" ];
                        trusted-public-keys = [
                            "nushell-nightly.cachix.org-1:nLwXJzwwVmQ+fLKD6aH6rWDoTC73ry1ahMX9lU87nrc="
                        ];
                    };
                }

                #
                # SECTION: Settings module
                #
                {
                    options.programs.nushell = {
                        package = lib.mkPackageOption pkgs "nushell" { };

                        # We wrap the executable to pass some arguments
                        finalPackage = lib.mkOption {
                            type = lib.types.package;
                            readOnly = true;
                            description = "Resulting package.";
                            default = pkgs.wrapped.nushell;
                        };

                        shellInit = lib.mkOption {
                            type = lib.types.lines;
                            description = "Configuration to be read by every shell";
                            default = "";
                        };

                        interactiveShellInit = lib.mkOption {
                            type = lib.types.lines;
                            description = "Configuration to be read only by interactive shells";
                            default = "";
                        };

                        loginShellInit = lib.mkOption {
                            type = lib.types.lines;
                            description = "Configuration to be read only by login shells";
                            default = "";
                        };

                        shellAliases = lib.mkOption {
                            type = lib.types.attrsOf lib.types.anything;
                            description = "A set of aliases for nushell.";
                            default = { };
                        };

                        plugins = lib.mkOption {
                            type = lib.types.listOf lib.types.package;
                            description = "A list of plugin packages to be installed and added to the nushell plugin registry.";
                            default = [ ];
                        };

                        libraries = lib.mkOption {
                            type = lib.types.listOf lib.types.path;
                            description = "A list of libraries to be installed and added to the nushell lib list.";
                            default = [ ];
                        };

                        experimentalOptions = lib.mkOption {
                            type = lib.types.listOf lib.types.str;
                            description = "Experimental options to enable";
                            default = [ ];
                        };
                    };
                }

                #
                # SECTION: Implementation
                #
                (
                    let
                        cfg = nixosConfig.programs.nushell;

                        mkAliases = aliases: lib.concatLines (lib.mapAttrsToList (k: v: "alias ${k} = ${v}") aliases);

                        loginNushellInit = # nu
                            pkgs.writeText "login.nu" ''
                                if not $nu.is-login { return }

                                ${cfg.loginShellInit}
                            '';

                        interactiveNushellInit = # nu
                            pkgs.writeText "interactive.nu" ''
                                if not $nu.is-interactive { return }

                                ${mkAliases cfg.shellAliases}
                                ${cfg.interactiveShellInit}
                            '';

                        nushellInit = # nu
                            pkgs.writeText "init.nu" ''
                                # Load libraries first
                                const NU_LIB_DIRS = $NU_LIB_DIRS ++ [
                                  ${lib.concatLines cfg.libraries}
                                ];

                                # Source Nixos Environment
                                if ("__NIXOS_SET_ENVIRONMENT_DONE" not-in $env) {
                                  ${pkgs.bash-env-json}/bin/bash-env-json ${nixosConfig.system.build.setEnvironment}
                                  | from json
                                  | get env
                                  | load-env
                                } 

                                # TODO: Make this configurable via a nix module option
                                # Setup env conversions AFTER sourcing general Nixos environment
                                # The order should not matter, but it does
                                export-env {
                                    def converter_by_separator [sep: string] {
                                        {
                                            from_string: {|s| $s | split row $sep }
                                            to_string: {|v| $v | str join $sep }
                                        }
                                    }

                                    let esep_list_converter = converter_by_separator (char esep)
                                    let space_list_converter = converter_by_separator (char space)

                                    $env.ENV_CONVERSIONS = {
                                        "DIRS_LIST": $esep_list_converter
                                        "GIO_EXTRA_MODULES": $esep_list_converter
                                        "GTK_PATH": $esep_list_converter
                                        "INFOPATH": $esep_list_converter
                                        "LIBEXEC_PATH": $esep_list_converter
                                        "LS_COLORS": $esep_list_converter
                                        "PATH": $esep_list_converter
                                        "QTWEBKIT_PLUGIN_PATH": $esep_list_converter
                                        "SESSION_MANAGER": $esep_list_converter
                                        "TERMINFO_DIRS": $esep_list_converter
                                        "XCURSOR_PATH": $esep_list_converter
                                        "XDG_CONFIG_DIRS": $esep_list_converter
                                        "XDG_DATA_DIRS": $esep_list_converter

                                        "NIX_PROFILES": $space_list_converter
                                    }
                                }

                                ${cfg.shellInit}
                                source ${loginNushellInit}
                                source ${interactiveNushellInit}

                                # Source user configuration if it exists
                                const def_user_config_file = $nu.default-config-dir | path join config.nu
                                source (if ($def_user_config_file | path exists) {$def_user_config_file})
                            '';

                        pluginConfig =
                            let
                                pluginExprs = map (plugin: "plugin add ${lib.getExe plugin}") cfg.plugins;
                            in
                            pkgs.runCommandLocal "plugin.msgpackz" { nativeBuildInputs = [ pkgs.nushell ]; } ''
                                touch $out {config,env}.nu
                                nu --config config.nu \
                                --env-config env.nu \
                                --plugin-config plugin.msgpackz \
                                --no-history \
                                --no-std-lib \
                                --commands '${lib.concatStringsSep ";" pluginExprs};'
                                cp plugin.msgpackz $out
                            '';
                    in
                    {
                        wrappers.nushell = {
                            basePackage = cfg.package;
                            pathAdd = cfg.plugins;
                            env.NU_EXPERIMENTAL_OPTIONS.value = (lib.concatStringsSep "," cfg.experimentalOptions);
                            prependFlags = [
                                "--config"
                                nushellInit
                                "--plugin-config"
                                pluginConfig
                            ];
                        };

                        environment = {
                            systemPackages = [ cfg.finalPackage ];
                            pathsToLink = [ "/share/nushell/vendor/autoload" ];
                            shells = [
                                "/run/current-system/sw/bin/nu"
                                (lib.getExe cfg.finalPackage)
                            ];
                        };
                    }
                )
            ];
        };
}
