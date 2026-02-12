{ hyprland, hyprland-plugins, ... }:
{
    graphical =
        {
            pkgs,
            config,
            lib,
            ...
        }:
        let
            # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
            workspaces = builtins.concatLists (
                builtins.genList (
                    x:
                    let
                        ws =
                            let
                                c = (x + 1) / 10;
                            in
                            builtins.toString (x + 1 - (c * 10));
                    in
                    [
                        "$mod, ${ws}, workspace, ${toString (x + 1)}"
                        "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
                    ]
                ) 10
            );

            toggle =
                program:
                let
                    prog = builtins.substring 0 14 program;
                in
                "pkill ${prog} || uwsm app -- ${program}";

            runOnce = program: "pgrep ${program} || uwsm app -- ${program}";
        in
        {
            imports = [ hyprland.nixosModules.default ];

            programs = {
                uwsm = {
                    desktopNames = [ "Hyprland" ];
                    sessionVariables.hyprland = {
                        HYPRCURSOR_SIZE = config.style.cursor.size;
                    };
                };

                hyprland = {
                    enable = true;
                    withUWSM = true;
                    package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
                    plugins = with hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}; [ hyprscrolling ];
                    settings = {
                        "$mod" = "SUPER";
                        animations = {
                            enabled = true;

                            bezier = [
                                "easeInOutQuart,0.76,0,0.24,1"
                                "fluentDecel, 0, 0.2, 0.4, 1"
                                "easeOutCirc, 0, 0.55, 0.45, 1"
                                "easeOutCubic, 0.33, 1, 0.68, 1"
                                "easeinoutsine, 0.37, 0, 0.63, 1"
                                "easeOutQuint, 0.23, 1, 0.32, 1"
                            ];

                            animation = [
                                "windowsIn, 1, 3, easeOutCubic, popin 30%"
                                "windowsOut, 1, 3, fluentDecel, popin 70%"
                                "windowsMove, 1, 4, easeOutQuint"
                                "fadeIn, 1, 3, easeOutCubic"
                                "fadeOut, 1, 1.7, easeOutCubic"
                                "fadeSwitch, 0, 1, easeOutCirc"
                                "fadeDim, 1, 4, fluentDecel"
                                "workspaces, 1, 3, easeOutCubic, slide"
                                "specialWorkspace, 1, 3, easeOutCubic, slidevert"
                                "layers, 1, 4, easeOutQuint"
                            ];
                        };
                        render = {
                            new_render_scheduling = true;
                            direct_scanout = true;
                            expand_undersized_textures = false;
                        };
                        xwayland = {
                            # xwayland scaling looks terrible
                            force_zero_scaling = true;
                        };
                        bind = [
                            # compositor commands
                            # "$mod SHIFT, E, exec, pkill Hyprland"
                            "$mod, Space, exec, vicinae toggle"
                            "$mod, Q, killactive,"
                            "$mod, F, fullscreen,"
                            "$mod, Y, togglegroup,"
                            "$mod SHIFT, N, changegroupactive, f"
                            "$mod SHIFT, P, changegroupactive, b"
                            "$mod, R, togglesplit,"
                            "$mod, G, togglefloating,"
                            "$mod, P, pseudo,"
                            "$mod ALT, ,resizeactive,"

                            # utility
                            # terminal
                            "$mod, T, exec, app2unit -t service com.mitchellh.ghostty.desktop:new-window"
                            # logout menu
                            "$mod, Escape, exec, ${toggle "wlogout"} -p layer-shell"
                            "$mod, O, exec, ${runOnce "wl-ocr"}"
                            ", XF86Favorites, exec, ${runOnce "wl-ocr"}"
                            # open calculator
                            ", XF86Calculator, exec, ${toggle "gnome-calculator"}"
                            # open settings
                            "$mod, U, exec, XDG_CURRENT_DESKTOP=gnome ${runOnce "gnome-control-center"}"

                            # move focus
                            "$mod, h, layoutmsg, focus l"
                            "$mod, l, layoutmsg, focus r"
                            "$mod SHIFT, h, layoutmsg, movewindowto l"
                            "$mod SHIFT, l, layoutmsg, movewindowto r"

                            "$mod, j, workspace, m-1"
                            "$mod, k, workspace, m+1"
                            "$mod SHIFT, j, movetoworkspace, m-1"
                            "$mod SHIFT, k, movetoworkspace, m+1"

                            # "$mod, k, movefocus, u"
                            # "$mod, j, movefocus, d"

                            # screenshot
                            # area
                            ", Print, exec, ${runOnce "grimblast"} --notify copysave area"
                            "$mod SHIFT, R, exec, ${runOnce "grimblast"} --notify copysave area"

                            # current screen
                            "CTRL, Print, exec, ${runOnce "grimblast"} --notify --cursor copysave output"
                            "$mod SHIFT CTRL, R, exec, ${runOnce "grimblast"} --notify --cursor copysave output"

                            # all screens
                            "ALT, Print, exec, ${runOnce "grimblast"} --notify --cursor copysave screen"
                            "$mod SHIFT ALT, R, exec, ${runOnce "grimblast"} --notify --cursor copysave screen"

                            # special workspace
                            "$mod SHIFT, grave, movetoworkspace, special"
                            "$mod, grave, togglespecialworkspace, eDP-1"

                            # cycle workspaces
                            "$mod, bracketleft, workspace, m-1"
                            "$mod, bracketright, workspace, m+1"

                            # cycle monitors
                            "$mod SHIFT, bracketleft, focusmonitor, l"
                            "$mod SHIFT, bracketright, focusmonitor, r"

                            # send focused workspace to left/right monitors
                            "$mod SHIFT ALT, bracketleft, movecurrentworkspacetomonitor, l"
                            "$mod SHIFT ALT, bracketright, movecurrentworkspacetomonitor, r"
                        ]
                        ++ workspaces;
                        bindl = [
                            # media controls
                            ", XF86AudioPlay, exec, playerctl play-pause"
                            ", XF86AudioPrev, exec, playerctl previous"
                            ", XF86AudioNext, exec, playerctl next"

                            # volume
                            ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
                            ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
                        ];
                        bindle = [
                            # volume
                            ", XF86AudioRaiseVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%+"
                            ", XF86AudioLowerVolume, exec, wpctl set-volume -l '1.0' @DEFAULT_AUDIO_SINK@ 6%-"

                            # backlight
                            ", XF86MonBrightnessUp, exec, brillo -q -u 300000 -A 5"
                            ", XF86MonBrightnessDown, exec, brillo -q -u 300000 -U 5"
                        ];
                        bindm = [
                            "$mod, mouse:272, movewindow"
                            "$mod, mouse:273, resizewindow"
                            "$mod ALT, mouse:272, resizewindow"
                        ];
                        bindr = [
                        ];

                        decoration = {
                            blur = {
                                enabled = true;
                                size = 2;
                                passes = 3;
                                xray = false;
                                special = true;
                            };
                            rounding = config.style.cornerRadius - 2;
                            rounding_power = 4;
                            shadow.enabled = false;
                        };

                        dwindle = {
                            preserve_split = true;
                            pseudotile = true;
                        };

                        general = {
                            layout = "scrolling";
                            allow_tearing = true;
                            border_size = config.style.borderWidth;
                            gaps_in = config.style.gapSize / 2;
                            gaps_out = config.style.gapSize;
                            resize_on_border = true;
                            "col.active_border" = "rgba(88888888)";
                            "col.inactive_border" = "rgba(00000088)";
                        };

                        gesture = [
                            "3, horizontal, workspace"
                            "4, left, dispatcher, movewindow, mon:-1"
                            "4, right, dispatcher, movewindow, mon:+1"
                            "4, pinch, fullscreen"
                        ];

                        gestures = {
                            workspace_swipe_forever = true;
                        };

                        input = {
                            follow_mouse = 1;
                            mouse_refocus = true;
                            accel_profile = "flat";
                            sensitivity = 0;

                            kb_layout = config.locale.keyboard-layout;
                            repeat_delay = 200;
                            repeat_rate = 30;

                            tablet = {
                                output = "current";
                                transform = 1;
                            };

                            touchpad = {
                                natural_scroll = true;
                                scroll_factor = "0.2";
                                clickfinger_behavior = true;
                                drag_lock = 0;
                            };
                        };

                        misc = {
                            animate_mouse_windowdragging = false;
                            force_default_wallpaper = 0;
                            vrr = 1;
                            disable_autoreload = true;
                            disable_hyprland_logo = true;
                            disable_watchdog_warning = true;
                            disable_splash_rendering = true;
                            focus_on_activate = false;
                            mouse_move_enables_dpms = true;
                            # To enable using keybinds when screen has been manually turned off
                            # off. Locker script enables this option.
                            key_press_enables_dpms = false;
                            background_color = "0x000000";
                            on_focus_under_fullscreen = 2;
                            enable_swallow = false;
                            # Otherwise it sometimes appears briefly during shutdown
                            lockdead_screen_delay = 10000;
                        };

                        plugin = {
                            hyprscrolling = {
                                column_width = 0.75;
                            };
                        };
                    };

                };

            };
        };
}
