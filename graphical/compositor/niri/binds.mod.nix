{
    graphical =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        {
            programs.niri.settings.binds =
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

                    onEachMonitor =
                        command:
                        spawn-sh (
                            config.programs.niri.settings.outputs
                            |> builtins.attrNames
                            |> builtins.length
                            |> builtins.genList (_: [
                                "niri msg action focus-monitor-next"
                                "niri msg action ${command}"
                            ])
                            |> builtins.concatLists
                            |> lib.concatStringsSep ";"
                        );
                in
                lib.attrsets.mergeAttrsList [

                    # ── compositor / session ─────────────────────────

                    {
                        "Mod+O".action = toggle-overview;
                        "Mod+Q".action = close-window;

                        "Mod+Tab".action = switch-focus-between-floating-and-tiling;
                        "Mod+W".action = toggle-window-floating;

                        # "Mod+Comma".action = consume-window-into-column;
                        # "Mod+Period".action = expel-window-from-column;
                        # "Mod+M".action = toggle-column-tabbed-display;

                        "Mod+F".action = maximize-window-to-edges;
                        "Mod+Shift+F".action = fullscreen-window;

                        "Mod+C".action = center-column;

                        "Mod+Shift+Escape".action = toggle-keyboard-shortcuts-inhibit;
                        "Mod+Shift+Ctrl+T".action = toggle-debug-tint;

                        "Mod+K".action = focus-window-up;
                        "Mod+J".action = focus-window-down;
                        "Mod+H".action = focus-column-left;
                        "Mod+L".action = focus-column-right;

                        "Mod+Ctrl+H".action = move-column-left;
                        "Mod+Ctrl+L".action = move-column-right;
                        "Mod+Ctrl+K".action = move-window-up;
                        "Mod+Ctrl+J".action = move-window-down;

                        "Mod+Shift+H".action = focus-monitor-left;
                        "Mod+Shift+L".action = focus-monitor-right;
                        "Mod+Shift+K".action = focus-monitor-up;
                        "Mod+Shift+J".action = focus-monitor-down;

                        "Mod+Ctrl+Shift+H".action = move-column-to-monitor-left;
                        "Mod+Ctrl+Shift+L".action = move-column-to-monitor-right;
                        "Mod+Ctrl+Shift+K".action = move-window-to-monitor-up;
                        "Mod+Ctrl+Shift+J".action = move-window-to-monitor-down;

                        "Mod+BracketLeft".action = focus-column-first;
                        "Mod+BracketRight".action = focus-column-last;

                        "Mod+I".action = focus-workspace-up;
                        "Mod+U".action = focus-workspace-down;
                        "Mod+Ctrl+I".action = move-column-to-workspace-up;
                        "Mod+Ctrl+U".action = move-column-to-workspace-down;
                        "Mod+Shift+I".action = move-workspace-up;
                        "Mod+Shift+U".action = move-workspace-down;

                        "Mod+WheelScrollUp" = {
                            action = focus-workspace-up;
                            cooldown-ms = 150;
                        };
                        "Mod+WheelScrollDown" = {
                            action = focus-workspace-down;
                            cooldown-ms = 150;
                        };
                        "Mod+Ctrl+WheelScrollUp" = {
                            action = move-column-to-workspace-up;
                            cooldown-ms = 150;
                        };
                        "Mod+Ctrl+WheelScrollDown" = {
                            action = move-column-to-workspace-down;
                            cooldown-ms = 150;
                        };
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
                ];
        };

    zeph =
        { config, ... }:
        {
            programs.niri.settings = {
                input = {
                    touch.map-to-output = "BOE 0x0A68 Unknown";
                    tablet.map-to-output = "BOE 0x0A68 Unknown";
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
                        action = spawn-sh "asusctl leds next";
                    };
                    "XF86Launch3" = {
                        allow-when-locked = true;
                        action = spawn-sh "asusctl aura --next-mode";
                    };
                    "XF86Launch4" = {
                        allow-when-locked = true;
                        action = spawn-sh "asusctl profile next";
                    };
                };
            };
        };
}
