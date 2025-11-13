{
    dms,
    dgop,
    quickshell,
    matugen,
    dms-plugins,
    ...
}:
{
    graphical =
        {
            pkgs,
            lib,
            homeConfig,
            dmsPkgs,
            ...
        }:
        let
            system = pkgs.stdenv.hostPlatform.system;

            latest = {
                matugen = matugen.packages.${system}.default;
                quickshell = quickshell.packages.${system}.default;
                dms = dms.packages.${system}.dankMaterialShell;
                dms-cli = dms.packages.${system}.dmsCli;
                dgop = dgop.packages.${system}.default;
            };
        in
        {
            imports = [ dms.nixosModules.greeter ];

            programs.dankMaterialShell.greeter = {
                enable = true;
                compositor.name = "niri";
                configHome = "/home/arakhor";
            };

            services.accounts-daemon.enable = true;

            preserveSystem.directories = [
                {
                    directory = "/var/lib/dmsgreeter";
                    mode = "755";
                    user = "greeter";
                    group = "greeter";
                }
                "/var/lib/AccountsService"
            ];

            preserveHome = {
                directories = [
                    ".local/state/DankMaterialShell"
                    ".config/DankMaterialShell"
                    ".cache/DankMaterialShell"
                ];
            };

            programs.nushell.loginShellInit = # nu
                ''
                    activate
                '';

            home = {
                systemd.services.dms = {
                    description = "Dank Material Shell (DMS)";

                    partOf = [ homeConfig.maid.systemdGraphicalTarget ];
                    requisite = [ homeConfig.maid.systemdGraphicalTarget ];
                    after = [ homeConfig.maid.systemdGraphicalTarget ];

                    environment.PATH = lib.mkForce null;

                    serviceConfig = {
                        Type = "simple";
                        ExecStart = "${latest.dms-cli}/bin/dms run --session";
                        ExecReload = "${pkgs.procps}/bin/pkill -USR1 -x dms";
                        Restart = "always";
                        RestartSec = 2;
                        TimeoutStopSec = 10;
                    };

                    wantedBy = [ "graphical-session.target" ];
                };

                packages = [
                    # Core
                    latest.quickshell
                    dmsPkgs.dankMaterialShell
                    dmsPkgs.dmsCli

                    pkgs.ddcutil
                    pkgs.libsForQt5.qt5ct
                    pkgs.kdePackages.qt6ct

                    # System Monitoring
                    dmsPkgs.dgop

                    # Clipboard
                    pkgs.cliphist
                    pkgs.wl-clipboard-rs

                    # Networking
                    pkgs.glib
                    pkgs.networkmanager

                    # Brightness
                    pkgs.brightnessctl

                    # Color Picker
                    pkgs.hyprpicker

                    # Dynamic Theming
                    pkgs.matugen

                    # Audio Visualiser
                    pkgs.cava

                    # Calendar Events
                    pkgs.khal

                    # System Sounds
                    pkgs.kdePackages.qtmultimedia
                    pkgs.ffmpeg

                    # Polkit
                    pkgs.mate.mate-polkit
                ];

                programs.niri.extraConfig = ''
                    include "dms/colors.kdl"
                '';

                programs.niri.settings = {
                    binds =
                        with homeConfig.lib.niri.actions;
                        let
                            dms-ipc = spawn "dms" "ipc";
                        in
                        {
                            "Mod+Space" = {
                                action = dms-ipc "spotlight" "toggle";
                                hotkey-overlay.title = "Toggle Application Launcher";
                            };
                            "Mod+N" = {
                                action = dms-ipc "notifications" "toggle";
                                hotkey-overlay.title = "Toggle Notification Center";
                            };
                            "Mod+S" = {
                                action = dms-ipc "settings" "toggle";
                                hotkey-overlay.title = "Toggle Settings";
                            };
                            "Mod+P" = {
                                action = dms-ipc "notepad" "toggle";
                                hotkey-overlay.title = "Toggle Notepad";
                            };
                            "Super+Alt+L" = {
                                action = dms-ipc "lock" "lock";
                                hotkey-overlay.title = "Toggle Lock Screen";
                            };
                            "Mod+X" = {
                                action = dms-ipc "powermenu" "toggle";
                                hotkey-overlay.title = "Toggle Power Menu";
                            };
                            "XF86AudioRaiseVolume" = {
                                allow-when-locked = true;
                                action = dms-ipc "audio" "increment" "3";
                            };
                            "XF86AudioLowerVolume" = {
                                allow-when-locked = true;
                                action = dms-ipc "audio" "decrement" "3";
                            };
                            "XF86AudioMute" = {
                                allow-when-locked = true;
                                action = dms-ipc "audio" "mute";
                            };
                            "XF86AudioMicMute" = {
                                allow-when-locked = true;
                                action = dms-ipc "audio" "micmute";
                            };
                            "Mod+Alt+N" = {
                                allow-when-locked = true;
                                action = dms-ipc "night" "toggle";
                                hotkey-overlay.title = "Toggle Night Mode";
                            };
                            "Mod+M" = {
                                action = dms-ipc "processlist" "toggle";
                                hotkey-overlay.title = "Toggle Process List";
                            };
                            "Mod+V" = {
                                action = dms-ipc "clipboard" "toggle";
                                hotkey-overlay.title = "Toggle Clipboard Manager";
                            };
                            "XF86MonBrightnessUp" = {
                                allow-when-locked = true;
                                action = dms-ipc "brightness" "increment" "5" "";
                            };
                            "XF86MonBrightnessDown" = {
                                allow-when-locked = true;
                                action = dms-ipc "brightness" "decrement" "5" "";
                            };
                        };
                };
            };

        };
}
