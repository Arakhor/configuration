{
    graphical =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        {
            services.keyd = {
                enable = true;
                keyboards = {
                    default = {
                        ids = [ "*" ];
                        settings = {
                            global.overload_tap_timeout = 200; # Milliseconds to register a tap before timeout
                            main = {
                                capslock = "overload(control, esc)";
                            };
                            navigation = {
                                h = "left";
                                j = "down";
                                k = "up";
                                l = "right";
                                u = "pageup";
                                d = "pagedown";
                            };
                        };
                    };
                };
            };

            programs.niri.settings = {
                input = {
                    focus-follows-mouse.enable = true;
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

                binds =
                    with config.lib.niri.actions;
                    let
                        playerctl = spawn "${pkgs.playerctl}/bin/playerctl";
                        brillo = spawn "${pkgs.brillo}/bin/brillo" "-u" "50000" "-e";

                        # ── helpers ───────────────────────────────────────

                        overviewTernary =
                            {
                                onOverview,
                                otherwise ? null,
                            }:
                            spawn-sh (
                                ''
                                    if niri msg overview-state | grep -q "is open"; then
                                      ${onOverview}
                                ''
                                + lib.optionalString (otherwise != null) ''
                                    else
                                      ${otherwise}
                                ''
                                + ''
                                    fi
                                ''
                            );
                    in
                    lib.attrsets.mergeAttrsList [

                        # ── compositor / session ─────────────────────────

                        {
                            "Mod+T".action = spawn "app2unit-term-service";

                            "Mod+O".action = toggle-overview;
                            "Mod+Q".action = close-window;

                            "Mod+Shift+P".action = power-off-monitors;

                            "Mod+G".action = switch-focus-between-floating-and-tiling;
                            "Mod+Ctrl+G".action = toggle-window-floating;

                            # "Mod+I".action = consume-window-into-column;
                            # "Mod+O".action = expel-window-from-column;
                            # "Mod+W".action = toggle-column-tabbed-display;

                            "Mod+M".action = maximize-window-to-edges;
                            "Mod+F".action = fullscreen-window;

                            "Mod+C".action = center-column;

                            "Mod+Shift+Escape".action = toggle-keyboard-shortcuts-inhibit;
                            "Mod+Shift+Ctrl+T".action = toggle-debug-tint;
                        }

                        # ── media / hardware ─────────────────────────────

                        {
                            "XF86AudioPlay".action = playerctl "play-pause";
                            "XF86AudioStop".action = playerctl "pause";
                            "XF86AudioPrev".action = playerctl "previous";
                            "XF86AudioNext".action = playerctl "next";

                            "XF86AudioRaiseVolume".action = spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
                            "XF86AudioLowerVolume".action = spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
                            "XF86AudioMute".action = spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                            "XF86AudioMicMute".action = spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

                            "XF86MonBrightnessUp".action = brillo "-A" "10";
                            "XF86MonBrightnessDown".action = brillo "-U" "10";

                            "Mod+Shift+S".action.screenshot = [ ];
                            "Print".action.screenshot-screen = [ ];
                            "Mod+Print".action.screenshot-window = [ ];

                            "Mod+Insert".action = set-dynamic-cast-window;
                            "Mod+Shift+Insert".action = set-dynamic-cast-monitor;
                            "Mod+Delete".action = clear-dynamic-cast-target;
                        }

                        # ── column size presets ──────────────────────────

                        (
                            let
                                inherit (config.programs.niri.settings.layout)
                                    preset-column-widths
                                    preset-window-heights
                                    ;

                                toPercent =
                                    p:
                                    let
                                        scaled = p.proportion * 100.0 * 10000.0;
                                        rounded = builtins.floor (scaled + 0.5) / 10000.0;
                                    in
                                    "${toString rounded}%";

                                mkBinds =
                                    prefix: action: presets:
                                    lib.listToAttrs (
                                        lib.imap0 (i: p: {
                                            name = "${prefix}+${toString (i + 1)}";
                                            value.action.${action} = [ (toPercent p) ];
                                        }) presets
                                    );
                            in
                            lib.attrsets.mergeAttrsList [
                                (mkBinds "Mod" "set-column-width" preset-column-widths)
                                (mkBinds "Mod+Shift" "set-window-height" preset-window-heights)
                            ]
                        )

                        # ── relative resize ──────────────────────────────

                        {
                            "Mod+Minus".action = set-column-width "-10%";
                            "Mod+Equal".action = set-column-width "+10%";

                            "Mod+Shift+Minus".action = set-window-height "-10%";
                            "Mod+Shift+Equal".action = set-window-height "+10%";
                        }

                        {
                            # push out of this monitor
                            "Mod+P".action = spawn-sh (
                                [
                                    "move-window-to-monitor-next"
                                    "focus-monitor-previous"
                                ]
                                |> map (v: "niri msg action " + v)
                                |> builtins.concatStringsSep ";"
                            );

                            # pull into this monitor
                            "Mod+Shift+P".action = spawn-sh (
                                [
                                    "focus-monitor-next"
                                    "move-window-to-monitor-previous"
                                ]
                                |> map (v: "niri msg action " + v)
                                |> builtins.concatStringsSep ";"
                            );
                        }

                        {
                            "Mod+K".action = focus-window-or-monitor-up;
                            "Mod+J".action = focus-window-or-monitor-down;
                            "Mod+H".action = focus-column-left;
                            "Mod+L".action = focus-column-right;

                            "Mod+Ctrl+H".action = move-column-left;
                            "Mod+Ctrl+L".action = move-column-right;
                            "Mod+Ctrl+K".action = move-column-to-monitor-up;
                            "Mod+Ctrl+J".action = move-column-to-monitor-down;

                            "Mod+A".action = focus-column-first;
                            "Mod+E".action = focus-column-last;

                            "Mod+I".action = focus-workspace-up;
                            "Mod+U".action = focus-workspace-down;
                            "Mod+Ctrl+I".action = move-window-to-workspace-up;
                            "Mod+Ctrl+U".action = move-window-to-workspace-down;
                        }
                    ];
            };
        };

    zeph =
        { config, ... }:
        {
            programs.niri.settings = {
                input = {
                    touch.map-to-output = "DP-3";
                    tablet.map-to-output = "DP-3";
                };
                binds = with config.lib.niri.actions; {
                    "Shift+XF86MonBrightnessUp" = {
                        allow-when-locked = true;
                        action = spawn-sh "brightnessctl set 10%+ -d asus_screenpad";
                    };
                    "Shift+XF86MonBrightnessDown" = {
                        allow-when-locked = true;
                        action = spawn-sh "brightnessctl set 10%- -d asus_screenpad";
                    };
                    "XF86KbdLightOnOff" = {
                        allow-when-locked = true;
                        action = spawn-sh "asusctl -n";
                    };
                    "XF86Launch3" = {
                        allow-when-locked = true;
                        action = spawn-sh "asusctl aura -n";
                    };
                    "XF86Launch4" = {
                        allow-when-locked = true;
                        action = spawn-sh "noctalia-shell ipc call powerProfile cycle";
                    };
                };
            };
        };
}
