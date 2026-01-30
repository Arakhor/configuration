{
    vicinae,
    vicinae-extensions,
    ...
}:
{
    graphical =
        {
            pkgs,
            lib,
            config,
            ...
        }:
        let
            jsonFormat = pkgs.formats.json { };
            tomlFormat = pkgs.formats.toml { };

            package = pkgs.vicinae;

            themes = { };

            environment = {
                USE_LAYER_SHELL = 1;
            };
        in
        {
            nixpkgs.overlays = [
                vicinae.overlays.default
                (final: prev: {
                    vicinaeExtensions = vicinae-extensions.packages.${final.stdenv.hostPlatform.system};
                })
            ];

            nix.settings = {
                substituters = [ "https://vicinae.cachix.org" ];
                trusted-public-keys = [ "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc=" ];
            };

            imports = [
                {
                    options.programs.vicinae = {
                        settings = lib.mkOption {
                            inherit (jsonFormat) type;
                            default = { };
                            description = "Settings written as JSON to `~/.config/vicinae/settings.json.";
                        };

                        extensions = lib.mkOption {
                            type = lib.types.listOf lib.types.package;
                            default = [ ];
                            description = ''
                                List of Vicinae extensions to install.
                                You can use the `mkVicinaeExtension` function from the overlay to create extensions.
                            '';
                        };
                    };
                }
            ];

            programs.vicinae.settings = {
                close_on_focus_loss = true;
                # escape_key_behavior = "close_window";
                consider_preedit = true;
                pop_to_root_on_close = false;
                favicon_service = "twenty";
                search_files_in_root = true;
                providers.applications.preferences.launchPrefix = "app2unit -t service --";

                font.normal = {
                    size = 10.5;
                    normal = config.style.fonts.sansSerif.name;
                };
                theme = {
                    light.name = "matugen";
                    dark.name = "matugen";
                    light.icon_theme = config.style.icons.name;
                    dark.icon_theme = config.style.icons.name;
                };
                launcher_window = {
                    opacity = config.style.opacity;
                    client_side_decorations.rounding = config.style.cornerRadius;
                    client_side_decorations.border_width = config.style.borderWidth * 2;
                    # compact_mode.enabled = true;
                    layer_shell.layer = "overlay";
                };
                fallbacks = [
                    "@fearoffish/kagi-search:index"
                    "files:search"
                ];
            };

            programs.vicinae.extensions = with pkgs.vicinaeExtensions; [
                bluetooth
                niri
                nix
                pulseaudio
                wifi-commander
                (pkgs.mkRayCastExtension {
                    name = "kagi-search";
                    sha256 = "sha256-hdzQDGa0Fb2Vf2uEDj9pBwnDn4E+F0bueI1lzq+W1EU=";
                    rev = "e76d9495d40dcb4ba9d46c575616ce07f11ad516";
                })
            ];

            environment.systemPackages = [ package ];

            maid-users = {
                file =
                    let
                        themeFiles = lib.mapAttrs' (
                            name: theme:
                            lib.nameValuePair "vicinae/themes/${name}.toml" {
                                source = tomlFormat.generate "vicinae-${name}-theme" theme;
                            }
                        ) themes;
                    in
                    {
                        xdg_config = {
                            "vicinae/settings.json" = lib.mkIf (config.programs.vicinae.settings != { }) {
                                source = jsonFormat.generate "vicinae-settings" config.programs.vicinae.settings;
                            };
                        };
                        xdg_data =
                            builtins.listToAttrs (
                                map (item: {
                                    name = "vicinae/extensions/${item.name}";
                                    value.source = item;
                                }) config.programs.vicinae.extensions
                            )
                            // themeFiles;
                    };

                systemd.services.vicinae = {
                    description = "Vicinae server daemon";
                    documentation = [ "https://docs.vicinae.com" ];
                    after = [ config.lib.session.graphicalTarget ];
                    partOf = [ config.lib.session.graphicalTarget ];

                    serviceConfig = {
                        Environment = lib.mapAttrsToList (
                            key: val:
                            let
                                valueStr = if lib.isBool val then (if val then "1" else "0") else toString val;
                            in
                            "${key}=${valueStr}"
                        ) environment;
                        Type = "simple";
                        ExecStart = "${lib.getExe' package "vicinae"} server";
                        Restart = "always";
                        RestartSec = 5;
                        KillMode = "process";
                        Slice = config.lib.session.appSlice;
                    };

                    unitConfig.X-Restart-Triggers = [
                        config.users.users.arakhor.maid.file.xdg_config."vicinae/settings.json".source
                    ];

                    environment = {
                        PATH = lib.mkForce null;
                    };

                    wantedBy = [ config.lib.session.graphicalTarget ];
                };
            };

            programs.niri.settings = {
                binds = with config.lib.niri.actions; {
                    "Mod+Space".action = spawn "vicinae" "toggle";
                    "Mod+Slash".action = spawn-sh "vicinae vicinae://extensions/fearoffish/kagi-search/index";
                    "Mod+V".action = spawn-sh "vicinae vicinae://extensions/vicinae/clipboard/history";
                    # "Mod+G".action = spawn-sh "vicinae vicinae://extensions/vicinae/clipboard/history";

                };
                layer-rules = lib.singleton {
                    matches = lib.singleton {
                        namespace = "^vicinae$";
                    };
                    shadow.enable = true;
                };
            };

            preserveHome.directories = [ ".local/share/vicinae" ];

            style.dynamic.templates.vicinae =
                let
                    keys = config.lib.style.genMatugenKeys { };
                    tomlFormat = pkgs.formats.toml { };
                in
                with keys;
                {
                    hooks.after = "${pkgs.vicinae}/bin/vicinae theme set matugen";
                    target = ".local/share/vicinae/themes/matugen.toml";
                    source = tomlFormat.generate "matugen-vicinae.toml" {
                        meta = {
                            description = "Theme generated with matugen  - ${mode} variant";
                            icon = "";
                            name = "matugen";
                            variant = mode;
                        };

                        colors = {
                            accents = {
                                blue = primary;
                                cyan = {
                                    lighter = 50;
                                    name = primary;
                                };
                                green = success;
                                magenta = secondary;
                                orange = {
                                    lighter = 40;
                                    name = error;
                                };
                                purple = tertiary;
                                red = error;
                                yellow = warning;
                            };
                            button = {
                                primary = {
                                    background = surface_container_high;
                                    focus = {
                                        outline = primary;
                                    };
                                    foreground = on_surface;
                                    hover = {
                                        background = surface_container_highest;
                                    };
                                };
                            };
                            core = {
                                accent = primary;
                                accent_foreground = on_primary;
                                background = surface_container;
                                foreground = on_surface;
                                secondary_background = surface_container_high;
                                border = outline_variant;
                            };
                            grid = {
                                item = {
                                    background = surface_container_highest;
                                    hover = {
                                        outline = {
                                            name = secondary;
                                            opacity = 0.8;
                                        };
                                    };
                                    selection = {
                                        outline = {
                                            name = primary;
                                        };
                                    };
                                };
                            };
                            input = {
                                border = outline;
                                border_error = error;
                                border_focus = primary;
                            };
                            list = {
                                item = {
                                    hover = {
                                        background = {
                                            name = primary_container;
                                            opacity = 0.25;
                                        };
                                        foreground = on_surface;
                                    };
                                    selection = {
                                        background = {
                                            name = primary_container;
                                            opacity = 0.5;
                                        };
                                        foreground = on_primary_container;
                                        secondary_background = primary_container;
                                        secondary_foreground = on_primary_container;
                                    };
                                };
                            };
                            loading = {
                                bar = primary;
                                spinner = primary;
                            };
                            main_window = {
                                border = primary;
                            };
                            scrollbars = {
                                background = {
                                    name = primary;
                                    opacity = 0.2;
                                };
                            };
                            settings_window = {
                                border = outline;
                            };
                            text = {
                                danger = warning;
                                default = on_surface;
                                links = {
                                    default = primary;
                                    visited = {
                                        darker = 20;
                                        name = tertiary;
                                    };
                                };
                                muted = on_surface_variant;
                                placeholder = {
                                    name = on_surface_variant;
                                    opacity = 0.6;
                                };
                                selection = {
                                    background = primary_container;
                                    foreground = on_primary_container;
                                };
                                success = success;
                            };
                        };
                    };
                };
        };
}
