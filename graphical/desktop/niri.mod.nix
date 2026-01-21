{
    niri,
    niri-fork,
    ...
}:
{
    graphical =
        {
            pkgs,
            config,
            lib,
            ...
        }:
        let
            cfg = config.programs.niri;
            inherit (config) style;
        in
        {
            imports = [
                {
                    options.programs.niri = {
                        extraConfig = lib.mkOption {
                            type = lib.types.lines;
                            description = "Extra lines to add after config validation.";
                            default = "";
                        };
                        settings-validation-package = lib.mkPackageOption pkgs "niri" { nullable = true; };
                        settings = lib.mkOption {
                            type = niri.lib.settings.make-type {
                                inherit lib pkgs;
                                modules = [ { _module.filename = "user-config.kdl"; } ];
                            };
                            default = { };
                        };
                    };
                    config = {
                        lib.niri.actions = lib.mergeAttrsList (
                            map (name: { ${name} = niri.lib.kdl.magic-leaf name; }) (import "${niri}/memo-binds.nix")
                        );
                        maid-users.file.xdg_config."niri/config.kdl".text = lib.concatLines [
                            (builtins.readFile (cfg.settings.validated { package = cfg.settings-validation-package; }))
                            cfg.extraConfig
                        ];
                    };
                }
            ];

            nixpkgs.overlays = [
                niri.overlays.niri
                niri-fork.overlays.default
            ];

            environment.systemPackages = with pkgs; [
                alacritty
                libnotify
                wl-clipboard
                wayland-utils
                libsecret
                cage
                gamescope
                xwayland-satellite
            ];

            programs.uwsm = {
                defaultDesktop = "${config.programs.niri.package}/share/wayland-sessions/niri.desktop";
                desktopNames = [ "niri" ];
                waylandCompositors.niri = {
                    prettyName = "niri";
                    comment = "niri compositor managed by UWSM";
                    binPath = "/run/current-system/sw/bin/niri-session";
                };
            };

            # Sets the window to urgent on command completion
            # programs.nushell.settings.hooks = {
            #     pre_execution = lib.singleton "$env._WINDOW_ID = (niri msg --json focused-window | from json | get id)";
            #     pre_prompt = lib.singleton "if $env has _WINDOW_ID {niri msg action set-window-urgent --id $env._WINDOW_ID}; hide-env -i _WINDOW_ID";
            # };

            programs.niri.enable = true;
            programs.niri.package = pkgs.niri-unstable;
            programs.niri.settings = {
                hotkey-overlay.skip-at-startup = true;
                prefer-no-csd = true;
                # clipboard.disable-primary = true;

                screenshot-path = "~/pictures/screenshots/%Y-%m-%dT%H:%M:%S.png";

                debug = {
                    honor-xdg-activation-with-invalid-serial = true;
                    wait-for-frame-completion-before-queueing = true; # nvidia
                    # render-drm-device = "/dev/dri/renderD129";
                };

                cursor = {
                    hide-when-typing = true;
                    theme = style.cursor.name;
                    size = style.cursor.size;
                };

                # switch-events =
                #   let
                #     sh = spawn "sh" "-c";
                #   in
                #   {
                #     tablet-mode-on.action = sh "notify-send tablet-mode-on";
                #     tablet-mode-off.action = sh "notify-send tablet-mode-off";
                #     lid-open.action = sh "notify-send lid-open";
                #     lid-close.action = sh "notify-send lid-close";
                #   };

                overview = {
                    zoom = 0.5;
                    workspace-shadow.enable = false;
                };

                layout = {
                    always-center-single-column = false;
                    # default-column-display = "normal";
                    empty-workspace-above-first = false;

                    gaps = style.gapSize;
                    struts.left = style.gapSize * 4;
                    struts.right = style.gapSize * 4;

                    background-color = "transparent";

                    preset-column-widths = [
                        { proportion = 1.0 / 3.0; }
                        { proportion = 1.0 / 2.0; }
                        { proportion = 2.0 / 3.0; }
                        { proportion = 1.0 / 1.0; }
                    ];

                    preset-window-heights = [
                        { proportion = 1.0 / 3.0; }
                        { proportion = 1.0 / 2.0; }
                        { proportion = 2.0 / 3.0; }
                        { proportion = 1.0 / 1.0; }
                    ];

                    default-column-width = {
                        proportion = 2.0 / 3.0;
                    };

                    border = {
                        enable = true;
                        width = style.borderWidth;
                    };

                    focus-ring.enable = false;

                    shadow = {
                        enable = true;
                        softness = 22;
                        spread = 1;
                        offset = {
                            x = 2;
                            y = 3;
                        };
                    };

                    # tab-indicator = {
                    #     position = "right";
                    #     hide-when-single-tab = true;
                    #     place-within-column = true;
                    #     gap = -16;
                    #     width = 4;
                    #     length.total-proportion = 0.3;
                    #     corner-radius = 8;
                    #     gaps-between-tabs = 2;
                    # };
                };

                gestures.dnd-edge-view-scroll = {
                    trigger-width = 64;
                    delay-ms = 250;
                    max-speed = 12000;
                };

                window-rules = [
                    {
                        geometry-corner-radius =
                            let
                                r = style.cornerRadius * 1.0;
                            in
                            {
                                top-left = r;
                                top-right = r;
                                bottom-left = r;
                                bottom-right = r;
                            };
                        clip-to-geometry = true;
                        draw-border-with-background = false;
                    }

                    {
                        matches = [
                            {
                                app-id = "^firefox$";
                                title = "^Picture-in-Picture$";
                            }
                        ];
                        open-focused = false;
                        open-floating = true;
                        default-column-width.fixed = 400;
                        default-window-height.fixed = 580;
                        default-floating-position = {
                            x = 32;
                            y = 32;
                            relative-to = "bottom-right";
                        };
                    }

                    # Gaming
                    {
                        matches = [
                            {
                                app-id = "steam";
                                title = "Friends List";
                            }
                        ];
                        open-focused = false;
                        open-floating = true;
                        default-column-width.fixed = 300;
                        default-window-height.fixed = 600;
                        default-floating-position = {
                            x = 32;
                            y = 32;
                            relative-to = "bottom-right";
                        };
                    }
                    {
                        matches = [
                            { app-id = "^.gamescope-wrapped$"; }
                            { app-id = "^steam_app_.*$"; }
                        ];
                        default-column-width.proportion = 1.0;
                        open-fullscreen = true;
                        variable-refresh-rate = true;
                    }
                ];
            };

            programs.niri.extraConfig = "include optional=true \"matugen.kdl\"";
            # programs.niri.settings.includes = [ { path = "matugen.kdl"; } ];

            style.dynamic.templates.niri =
                with lib.kdl;
                with (config.lib.style.genMatugenKeys { });
                let
                    generateKdl = name: document: pkgs.callPackage lib.kdl.generator { inherit name document; };
                    borderLike = [
                        (leaf "active-color" primary)
                        (leaf "inactive-color" outline_variant)
                        (leaf "urgent-color" tertiary)
                    ];
                in
                {
                    target = ".config/niri/matugen.kdl";
                    source = generateKdl "matugen-niri.kdl" [
                        (plain "layout" [
                            (plain "focus-ring" borderLike)
                            (plain "border" borderLike)
                            (plain "shadow" [ (leaf "color" "${shadow}80") ])
                            (plain "tab-indicator" [
                                (leaf "active-color" primary)
                                (leaf "inactive-color" primary_container)
                                (leaf "urgent-color" tertiary)
                            ])
                            (plain "insert-hint" [ (leaf "color" "${primary}80") ])
                        ])
                        (plain "recent-windows" [
                            (plain "highlight" [
                                (leaf "active-color" primary)
                                (leaf "urgent-color" tertiary)
                            ])
                        ])
                    ];
                };
        };

    xps.programs.niri.settings.outputs."eDP-1".scale = 2.5;

    zeph.programs.niri.settings = {
        outputs = rec {
            eDP-1 = {
                variable-refresh-rate = "on-demand";
                focus-at-startup = true;
                scale = 1.5;
                mode.width = 2560;
                mode.height = 1600;
                position.x = 0;
                position.y = 0;
            };
            eDP-2 = eDP-1;
            DP-3 = {
                scale = 2.25;
                mode.width = 3840;
                mode.height = 1100;
                position.x = 0;
                position.y = 1067;
            };
        };
    };

}
