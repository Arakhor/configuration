{
    graphical =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        {
            maid-users.file.xdg_config = {
                "swaync/config.json".source = (pkgs.formats.json { }).generate "config.json" {
                    control-center-layer = "top";
                    control-center-margin-bottom = 0;
                    control-center-margin-left = 0;
                    control-center-margin-right = 0;
                    control-center-margin-top = 0;
                    control-center-width = 500;
                    cssPriority = "application";
                    fit-to-screen = true;
                    hide-on-action = true;
                    hide-on-clear = false;
                    image-visibility = "when-available";
                    keyboard-shortcuts = true;
                    layer = "overlay";
                    layer-shell = true;
                    notification-2fa-action = true;
                    notification-body-image-height = 100;
                    notification-body-image-width = 200;
                    notification-inline-replies = false;
                    notification-visibility = { };
                    notification-window-width = 500;
                    positionX = "right";
                    positionY = "top";
                    relative-timestamps = true;
                    script-fail-notify = true;
                    scripts = { };
                    timeout = 10;
                    timeout-critical = 0;
                    timeout-low = 5;
                    transition-time = 200;
                    widget-config = {
                        title = {
                            button-text = "Clear All";
                            clear-all-button = true;
                            text = "Notifications";
                        };
                        dnd.text = "Do Not Disturb";
                        menubar = {
                            buttons = {
                                actions = [
                                    {
                                        active = true;
                                        command = "darkman toggle";
                                        label = "󰔎 Toggle Appearance";
                                        type = "toggle";
                                    }
                                ];
                                position = "left";
                            };
                            menu = {
                                actions = [
                                    {
                                        active = true;
                                        command = "swaylock";
                                        label = "󰌾 Lock";
                                    }
                                    {
                                        active = true;
                                        command = "systemctl sleep";
                                        label = "󰤄 Sleep";
                                    }
                                    {
                                        active = true;
                                        command = "systemctl poweroff";
                                        label = "󰐥 Shut down";
                                    }
                                    {
                                        active = true;
                                        command = "systemctl reboot";
                                        label = "󰜉 Restart";
                                    }
                                ];
                                animation-duration = 250;
                                animation-type = "slide_down";
                                label = "󰐥 Power";
                                position = "right";
                            };
                        };
                        mpris = {
                            autohide = true;
                            show-album-art = "when-available";
                        };
                        volume = {
                            collapse-button-label = "";
                            expand-button-label = "";
                            label = "Volume";
                            show-per-app = true;
                            show-per-app-icon = false;
                            show-per-app-label = true;
                        };
                    };
                    widgets = [
                        "title"
                        "dnd"
                        "menubar"
                        "notifications"
                        "mpris"
                        "volume"
                    ];
                };
            };

            systemd.user.services.swaync = {
                description = "Swaync notification daemon";
                documentation = [ "https://github.com/ErikReider/SwayNotificationCenter" ];
                partOf = [ "graphical-session.target" ];
                after = [ "graphical-session.target" ];

                unitConfig = {
                    ConditionEnvironment = "WAYLAND_DISPLAY";
                    X-Restart-Triggers = lib.mkMerge [
                        [ "${config.users.users.arakhor.maid.file.xdg_config."swaync/config.json".source}" ]
                        # (lib.mkIf (cfg.style != null) [ "${config.xdg.configFile."swaync/style.css".source}" ])
                    ];
                };

                serviceConfig = {
                    Type = "dbus";
                    BusName = "org.freedesktop.Notifications";
                    ExecStart = "${lib.getExe pkgs.swaynotificationcenter}";
                    Restart = "on-failure";
                    Slice = config.lib.session.backgroundSlice;
                };

                wantedBy = [ "graphical-session.target" ];
            };
        };
}
