let
    icons = rec {
        calendar = "󰃭 ";
        clock = " ";
        battery.charging = "󱐋";
        battery.horizontal = [
            " "
            " "
            " "
            " "
            " "
        ];
        battery.vertical = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
        ];
        battery.levels = battery.vertical;
        network.disconnected = "󰤮 ";
        network.ethernet = "󰈀 ";
        network.strength = [
            "󰤟 "
            "󰤢 "
            "󰤥 "
            "󰤨 "
        ];
        bluetooth.on = "󰂯";
        bluetooth.off = "󰂲";
        bluetooth.battery = "󰥉";
        volume.source = "󱄠";
        volume.muted = "󰝟";
        volume.low = "󰕿";
        volume.medium = "󰖀";
        volume.high = "󰕾";
        idle.on = "󰈈 ";
        idle.off = "󰈉 ";
        vpn = "󰌆 ";

        # notification.red-badge = "<span foreground='red'><sup></sup></span>";
        notification.bell = "󰂚";
        notification.bell-badge = "󱅫";
        notification.bell-outline = "󰂜";
        notification.bell-outline-badge = "󰅸";
    };

    modules = {
        workspaces = {
            type = "workspaces";
            all_monitors = true;
            format = "{id}";
            on_click = "focus";
        };

        focused = {
            type = "focused";
            show_icon = false;
        };

        # clock = {
        #     type = "clock";
        #     class = "module module-clock";
        #     format = "%a %h %d %R %p";
        #     tooltip_format = "<big>%A, %B %d, %Y</big>\n%H:%M:%S";
        # };

        date = {
            type = "clock";
            format = "${icons.calendar} %Y-%m-%d";
        };

        clock = {
            type = "clock";
            format = "${icons.clock} %H:%M:%S";
            interval = 1;
        };

        tray = {
            type = "tray";
            icon_size = 16;
            spacing = 3;
            direction = "h";
        };

        bluetooth = {
            type = "bluetooth";
            format = {
                enabled = icons.bluetooth.on;
                disabled = icons.bluetooth.off;
                connected = "${icons.bluetooth.on} {device_alias}";
                connected_battery = "${icons.bluetooth.on} {device_alias} {device_battery_percent}%";
            };
        };

        volume = {
            type = "volume";
            format = "{icon} {percentage}%";
            icons = {
                muted = icons.volume.muted;
                volume_high = icons.volume.high;
                volume_medium = icons.volume.medium;
                volume_low = icons.volume.low;
            };
        };

        source = {
            type = "volume";
            format = "${icons.volume.source} {name}";
        };

        notifications = {
            type = "notifications";
            show_count = true;
            icons = {
                closed_dnd = "󱅯";
                closed_none = "󰍥";
                closed_some = "󱥂";
                open_dnd = "󱅮";
                open_none = "󰍡";
                open_some = "󱥁";
            };
        };
    };

    mainBar = {
        layer = "top";
        position = "top";
        height = 28;
        exclusive = true;
        anchor_to_edges = true;
        start = with modules; [
            volume
            source
        ];
        center = with modules; [
            date
            clock
        ];
        end = with modules; [
            tray
            bluetooth
            notifications
        ];
    };
in
{
    graphical =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        {
            maid-users.packages = [ pkgs.ironbar ];

            maid-users.file.xdg_config = {
                "ironbar/config.json".source = (pkgs.formats.json { }).generate "config" {
                    icon_theme = config.style.icons.name;
                    monitors = {
                        eDP-1 = mainBar;
                        eDP-2 = mainBar;
                    };
                };
            };

            style.dynamic.templates.ironbar =
                let
                    keys = config.lib.style.genMatugenKeys { };
                    modules = s: "${s "#start"}, ${s "#center"}, ${s "#end"}";
                    module = s: modules (m: "${m} > ${s} > *");
                    inherit (config.style) cornerRadius;
                in
                rec {
                    target = ".config/ironbar/style.css";
                    hooks.after = (lib.getExe pkgs.ironbar) + " style load-css ~/${target}";
                    text = # css
                        with keys; ''
                            * {
                                border: none;
                                font-family: ${config.style.fonts.sansSerif.name};
                                font-size: 13px;
                                color: ${on_surface};
                            }

                            window {
                                background: transparent;
                            }

                            ${modules lib.id} {
                                margin: 3px 10px;
                            }

                            ${module "*"} {
                                margin: 3px 1px;
                                padding: 5px 7px;
                                background: ${surface};
                            }

                            ${module ":first-child"} {
                                padding-left: 10px;
                                border-top-left-radius: ${cornerRadius}px;
                                border-bottom-left-radius: ${cornerRadius}px;
                            }

                            ${module ":last-child"} {
                                padding-right: 10px;
                                border-top-right-radius: ${cornerRadius}px;
                                border-bottom-right-radius: ${cornerRadius}px;
                            }

                            ${module ":not(:first-child)"} {
                                border-top-left-radius: 3px;
                                border-bottom-left-radius: 3px;
                            }

                            ${module ":not(last-child)"} {
                                border-top-right-radius: 3px;
                                border-bottom-right-radius: 3px;
                            }
                        '';
                };

            systemd.user.services.ironbar = {
                description = "Ironbar Daemon";

                partOf = [ "graphical-session.target" ];
                requisite = [ "graphical-session.target" ];
                after = [ "graphical-session.target" ];

                environment.PATH = lib.mkForce null;

                serviceConfig = {
                    Slice = config.lib.session.backgroundSlice;
                    ExecStart = lib.getExe pkgs.ironbar;
                };

                wantedBy = [ "graphical-session.target" ];
            };
        };
}
