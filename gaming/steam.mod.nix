{ nix-gaming-edge, ... }:
{
    gaming =
        {
            pkgs,
            config,
            lib,
            ...
        }:
        {
            nixpkgs.overlays = [ nix-gaming-edge.overlays.proton-cachyos ];

            programs.steam = {
                enable = true;
                protontricks.enable = true;
                extraCompatPackages = with pkgs; [
                    proton-cachyos-x86_64-v3
                    proton-ge-bin
                ];
            };

            # Steam doesn't close cleanly when SIGTERM is sent to the main process so we
            # have to send SIGTERM to a specific child process and wait for the
            # steamwebhelper which likes to hang around.
            programs.uwsm.appUnitOverrides."steam@.service" =
                let
                    steamKiller = pkgs.writeShellApplication {
                        name = "steam-killer";
                        runtimeInputs = with pkgs; [
                            coreutils
                            systemd
                            gnugrep
                            gawk
                            gnused
                        ];
                        text = ''
                            processes=$(systemd-cgls --no-page --full --user-unit "$1")

                            get_pid() {
                              echo "$processes" | grep "$1" | awk '{print $1}' | sed 's/^[^0-9]*//'
                            }

                            pid_main=$(get_pid "steam -srt-logger-opened")
                            pid_helper=$(get_pid "./steamwebhelper -nocrashdialog -lang=en_US")

                            if [ -z "$pid_main" ] || [ -z "$pid_helper" ]; then
                              echo "Could not find required Steam PIDs, aborting"
                              exit 1
                            fi

                            if [ "$(echo "$pid_main$pid_helper" | wc -l)" -gt 1 ]; then
                              echo "Unexpectedly found multiple PIDs to kill, aborting"
                              exit 1
                            fi

                            echo "Sending SIGTERM to main Steam process..."
                            kill -s 15 "$pid_main"
                            while [ -e "/proc/$pid_main" ]; do sleep .5; done
                            echo "Main Steam process successfully killed"

                            echo "Waiting for steamwebhelper to exit..."
                            while [ -e "/proc/$pid_helper" ]; do sleep .5; done
                            echo "Steamwebhelper process successfully killed"
                        '';
                    };
                in
                ''
                    [Service]
                    ExecStop=-${lib.getExe steamKiller} %n
                '';

            # Fix slow steam client downloads https://redd.it/16e1l4h
            # Speed up shader processing by using more than a single thread
            maid-users.file.xdg_data."Steam/steam_dev.cfg".text = ''
                @nClientDownloadEnableHTTP2PlatformLinux 0
                unShaderBackgroundProcessingThreads ${toString (builtins.head config.hardware.facter.report.hardware.cpu).siblings}
            '';

            programs.niri.settings.window-rules = [
                {
                    matches = [
                        { app-id = "^steam_app_.*$"; }
                    ];
                    default-column-width.proportion = 1.0;
                    open-fullscreen = true;
                    variable-refresh-rate = true;
                }

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

            ];

            preserveHome.directories = [
                ".steam"
                ".local/share/Steam"
            ];
        };
}
