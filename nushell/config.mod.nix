{
    xs,
    nushell-nightly,
    helix,
    ...
}:
{
    universal =
        {
            lib,
            pkgs,
            config,
            ...
        }:
        {
            nixpkgs.overlays = [
                nushell-nightly.overlays.default
                (final: prev: {
                    cross-stream = xs.packages.${final.stdenv.hostPlatform.system}.default;
                })
            ];

            nix.settings.substituters = [ "https://nushell-nightly.cachix.org" ];
            nix.settings.trusted-public-keys = [
                "nushell-nightly.cachix.org-1:nLwXJzwwVmQ+fLKD6aH6rWDoTC73ry1ahMX9lU87nrc="
            ];

            users.users.arakhor.shell = config.programs.nushell.finalPackage;
            environment.systemPackages = [
                pkgs.jc
                pkgs.cross-stream
            ];

            programs.nushell = {
                enable = true;
                experimentalOptions = [
                    "pipefail"
                    "enforce-runtime-annotations"
                ];
                plugins = with pkgs.nushellPlugins; [
                    formats
                    gstat
                    query
                    # polars
                ];

                libraries = [
                    "${pkgs.nu_scripts}/share"
                    ./.
                ];

                shellAliases = {
                    fg = "job unfreeze";
                    ls = "ls-custom";
                    incognito = "exec nu --no-history";
                };

                initConfig =

                    lib.mkBefore /* nu */ ''
                        use std [
                            ellie
                            repeat
                            null-device
                            help
                            input
                            iter
                            random
                            dt
                            'path add'
                        ]
                        use std/formats [
                            'from ndjson'
                            'from jsonl'
                            'from ndnuon'
                            'to ndjson'
                            'to jsonl'
                            'to ndnuon'
                        ]
                        use std-rfc [
                            'into list'
                            columns-into-table
                            record-into-columns
                            table-into-columns
                            name-values
                            aggregate
                            'select slices'
                            'reject slices'
                            'select column-slices'
                            'reject column-slices'
                            'kv set'
                            'kv get'
                            'kv list'
                            'kv drop'
                            'kv universal-variable-hook'
                            str
                            iter
                        ]
                        use std-rfc/path
                        use nu-lib [
                            ls-custom
                            helix-to-nushell
                            theme-display-color
                            'from nix'
                            'to nix'
                            type
                        ]
                        use nu_scripts/modules/jc 

                        dircolors | parse "{var}='{val}';" | transpose -dr | load-env 
                    '';

                environmentVariables = with config.lib.nushell; {
                    ENV_CONVERSIONS = {
                        DIRS_LIST = esepListConverter;
                        GIO_EXTRA_MODULES = esepListConverter;
                        GTK_PATH = esepListConverter;
                        INFOPATH = esepListConverter;
                        LIBEXEC_PATH = esepListConverter;
                        LS_COLORS = esepListConverter;
                        PATH = esepListConverter;
                        NIX_PATH = esepListConverter;
                        GI_TYPELIB_PATH = esepListConverter;
                        GST_PLUGIN_SYSTEM_PATH_1_0 = esepListConverter;
                        QTWEBKIT_PLUGIN_PATH = esepListConverter;
                        SESSION_MANAGER = esepListConverter;
                        TERMINFO_DIRS = esepListConverter;
                        XCURSOR_PATH = esepListConverter;
                        XDG_CONFIG_DIRS = esepListConverter;
                        XDG_DATA_DIRS = esepListConverter;

                        APP2UNIT_SLICES = spaceListConverter;
                        NIX_PROFILES = spaceListConverter;
                    };
                };

                settings = {
                    show_banner = "short";
                    edit_mode = "vi";

                    cursor_shape.vi_insert = "line";
                    cursor_shape.vi_normal = "block";

                    use_kitty_protocol = true;
                    use_ansi_coloring = true;

                    hooks = {
                        pre_execution = [
                            "(kv universal-variable-hook)"
                        ];

                        pre_prompt = [
                            "try {$env.config.color_config = (helix-to-nushell matugen --repo ${helix} | theme-display-color )}"

                            # HACK: Workaround to reapply env conversions when external tools stringify environment variables.
                            # -> e.g., direnv changes PATH, vivid changes LS_COLORS.
                            "$env.ENV_CONVERSIONS = $env.ENV_CONVERSIONS"
                        ];

                        # Enable file icons
                        display_output = "if (term size).columns >= 100 { table -e --icons } else { table --icons}";
                    };

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

                    footer_mode = "auto";
                    table = {
                        footer_inheritance = true;
                        header_on_separator = true;
                        index_mode = "auto";
                        missing_value_symbol = "󰟢";
                        mode = "compact";
                        show_empty = true;
                        trim = {
                            methodology = "truncating";
                            truncating_suffix = "…";
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
            };

            preserveHome = {
                files = [
                    ".config/nushell/history.sqlite3"
                ];
                directories = [
                    ".cache/nushell"
                    ".local/share/nushell"
                ];
            };
        };
}
