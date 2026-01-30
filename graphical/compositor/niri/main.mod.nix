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
        in
        {
            imports = [
                {
                    options.programs.niri = {
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
                        programs.niri.settings-validation-package = lib.mkDefault cfg.package;
                        lib.niri.actions = lib.mergeAttrsList (
                            map (name: { ${name} = niri.lib.kdl.magic-leaf name; }) (import "${niri}/memo-binds.nix")
                        );
                        maid-users.file.xdg_config."niri/config.kdl".source = cfg.settings.validated {
                            package = cfg.settings-validation-package;
                        };
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
                xwayland-satellite
            ];

            programs = {
                wshowkeys.enable = true;

                uwsm = {
                    desktopNames = [ "niri" ];
                    waylandCompositors.niri = {
                        prettyName = "niri";
                        comment = "niri compositor managed by UWSM";
                        binPath = "/run/current-system/sw/bin/niri";
                    };
                };

                niri = {
                    enable = true;
                    package = pkgs.niri-unstable;

                    settings = {
                        hotkey-overlay.skip-at-startup = true;
                        # clipboard.disable-primary = true;
                        screenshot-path = "~/pictures/screenshots/%Y-%m-%dT%H:%M:%S.png";

                        debug = {
                            honor-xdg-activation-with-invalid-serial = true;
                        };

                        spawn-at-startup = [
                            {
                                # [Soteria systemd service does not start](https://github.com/NixOS/nixpkgs/issues/373290)
                                sh = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_ID";
                            }
                        ];

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

                        overview.zoom = 0.5;
                        layout = {
                            always-center-single-column = true;
                            empty-workspace-above-first = true;
                            # default-column-display = "normal";

                            default-column-width.proportion = 2.0 / 3.0;
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
                        };

                        input = {
                            focus-follows-mouse = {
                                enable = true;
                                # max-scroll-amount = "50%";
                            };
                            warp-mouse-to-focus.enable = true;
                            warp-mouse-to-focus.mode = "center-xy-always";
                            keyboard.xkb.layout = config.locale.keyboard-layout;

                            mouse = {
                                accel-profile = "flat";
                                accel-speed = 0.0;
                            };

                            touchpad = {
                                dwt = true;
                                tap = true;
                                natural-scroll = false;
                                click-method = "clickfinger";
                            };
                        };

                        gestures.dnd-edge-view-scroll = {
                            trigger-width = 64;
                            delay-ms = 250;
                            max-speed = 12000;
                        };

                        window-rules = [
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
                };
            };
        };

    xps.programs.niri.settings.outputs."eDP-1".scale = 2.5;

    zeph = {
        maid-users.file.xdg_config."uwsm/env-niri".text = ''
            export LIBVA_DRIVER_NAME=nvidia
            export GBM_BACKEND=nvidia-drm
            export __GLX_VENDOR_LIBRARY_NAME=nvidia
            export __GL_GSYNC_ALLOWED=0
            export __GL_VRR_ALLOWED=0
        '';

        programs.niri.settings = {
            debug = {
                # wait-for-frame-completion-before-queueing = true;
                render-drm-device = "/dev/dri/dgpu"; # NOTE: requires udev rules setup in core/asus
            };

            outputs =
                let
                    internal = {
                        variable-refresh-rate = true;
                        focus-at-startup = true;
                        scale = 1.5;
                        mode.width = 2560;
                        mode.height = 1600;
                        position.x = 0;
                        position.y = 0;
                    };
                    screenpad = {
                        scale = 2.25;
                        mode.width = 3840;
                        mode.height = 1100;
                        position.x = 0;
                        position.y = builtins.ceil (internal.mode.height / internal.scale);

                        layout.default-column-width.proportion = 1.0;
                    };
                in
                {
                    "BOE NE160QDM-NM4 Unknown" = internal;
                    "BOE 0x0A68 Unknown" = screenpad;
                };
        };
    };

}
