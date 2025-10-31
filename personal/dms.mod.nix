{ dankMaterialShell, quickshell, ... }:
{
    personal =
        {
            pkgs,
            homeConfig,
            dmsPkgs,
            ...
        }:
        {
            imports = [ dankMaterialShell.nixosModules.greeter ];
            nixpkgs.overlays = [ quickshell.overlays.default ];

            programs.dankMaterialShell.greeter = {
                enable = true;
                compositor.name = "niri";
                configHome = "/home/arakhor";
            };

            preserveSystem.directories = [ "/var/lib/dmsgreeter" ];
            preserveHome.directories = [
                ".local/state/DankMaterialShell"
                ".cache/DankMaterialShell"
                ".config/DankMaterialShell"
                ".config/niri/dms"
            ];

            # FIXME: actually figure out how to do it properly
            programs.bash.shellInit = "activate";

            services.accounts-daemon.enable = true;

            home = {
                programs.quickshell = {
                    enable = true;
                    configs.dms = "${dmsPkgs.dankMaterialShell}/etc/xdg/quickshell/dms";
                };

                # systemd.services.dms = {
                #   description = "DankMaterialShell";
                #   partOf = [ config.maid.systemdGraphicalTarget ];
                #   after = [ config.maid.systemdGraphicalTarget ];

                #   script = lib.getExe dmsPkgs.dmsCli + " run";
                #   path =  [
                #     config.programs.quickshell.package
                #   ];

                #   wantedBy = [ config.maid.systemdGraphicalTarget ];
                # };

                packages = [
                    pkgs.ddcutil
                    pkgs.libsForQt5.qt5ct
                    pkgs.kdePackages.qt6ct
                    pkgs.adw-gtk3

                    dmsPkgs.dmsCli

                    dmsPkgs.dgop
                    pkgs.cliphist
                    pkgs.wl-clipboard
                    pkgs.glib
                    pkgs.networkmanager
                    pkgs.brightnessctl
                    pkgs.hyprpicker
                    # matugen.packages.${pkgs.system}.default
                    pkgs.matugen

                    pkgs.cava
                    pkgs.khal
                    pkgs.kdePackages.qtmultimedia
                ];

                # programs.niri.extraConfig = ''
                #   include "dms/colors.kdl"
                # '';

                programs.nushell.extraConfig = # nu
                    ''
                        def dms-reload [] {
                            dms kill
                            niri msg action spawn -- dms run
                        }
                    '';

                programs.niri.settings = {
                    environment = {
                        QT_QPA_PLATFORMTHEME = "qt6ct";
                        QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
                    };

                    layer-rules = [
                        {
                            matches = [ { namespace = "quickshell"; } ];
                            place-within-backdrop = true;
                        }
                        {
                            matches = [ { namespace = "dms:blurwallpaper"; } ];
                            opacity = 0.0;
                        }
                        {
                            matches = [ { namespace = "dms:blurwallpaper"; } ];
                            place-within-backdrop = true;
                            opacity = 1.0;
                        }
                    ];

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

                    spawn-at-startup = [
                        { sh = "niri msg action do-screen-transition; dms run"; }
                        { sh = "wl-paste --watch cliphist store"; }
                    ];
                };
            };

        };
}
