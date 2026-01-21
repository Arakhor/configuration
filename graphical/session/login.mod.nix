{ niri, ... }:
{
    graphical =
        {
            lib,
            config,
            pkgs,
            ...
        }:
        {
            options.login = {
                niri.settings = lib.mkOption {
                    type = niri.lib.settings.make-type {
                        inherit lib pkgs;
                        modules = [ { _module.filename = "login-config.kdl"; } ];
                    };
                };
                default = { };

                tuigreet-width.proportion = lib.mkOption {
                    type = lib.types.float;
                    default = 0.5;
                };
            };

            config =
                let
                    niri-config = config.login.niri.settings.validated {
                        package = config.programs.niri.package;
                    };
                in
                {
                    login.niri.settings = {
                        includes = [ "${config.programs.niri.settings}" ];
                        hotkey-overlay.skip-at-startup = true;

                        layout = {
                            border.active.color = "#ffffff80";
                            center-focused-column = "always";
                            default-column-width.proportion = config.login.tuigreet-width.proportion;
                        };
                    };

                    services.greetd = {
                        enable = true;
                        useTextGreeter = true;
                        settings.default_session = {
                            # greetd should run as the greeter user otherwise it automatically logs
                            # in without prompting for password
                            user = "greeter";
                            # command = ''
                            #     ${lib.getExe pkgs.tuigreet} \
                            #     --time \
                            #     --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions \
                            #     --remember-session \
                            #     --remember \
                            #     --asterisks
                            # '';
                            command =
                                let
                                    niri = "/run/current-system/sw/bin/niri";
                                in
                                builtins.concatStringsSep " " [
                                    niri
                                    "-c"
                                    niri-config
                                    "--"
                                    "/usr/bin/env"
                                    # shader cache for the Blazingly Fast Terminal Emulators
                                    "XDG_CACHE_HOME=/tmp/greeter-cache"
                                    (lib.getExe pkgs.alacritty)
                                    "--config-file"
                                    config.users.users.arakhor.maid.file.xdg_config."alacritty/alacritty.toml".source
                                    "-e"
                                    (pkgs.writeScript "greet-cmd" ''
                                        ${lib.getExe pkgs.tuigreet} ${
                                            builtins.concatStringsSep " " [
                                                "--remember"
                                                "--asterisks"
                                                "--cmd"
                                                "${pkgs.writeScript "init-session" ''
                                                    UWSM_SILENT_START=1 exec uwsm start -- ${config.programs.uwsm.defaultDesktop}
                                                ''}"
                                            ]
                                        }
                                        "${niri} msg action quit --skip-confirmation"
                                    '')
                                ];
                        };
                    };

                    security = {
                        soteria.enable = true;
                        pam.services.greetd = {
                            enableGnomeKeyring = true;
                            u2fAuth = true;
                        };
                        polkit.enable = true;
                    };

                    systemd.user.services.polkit-soteria = {
                        path = lib.mkForce [ ];
                        requisite = [ "graphical-session.target" ];
                        serviceConfig.Slice = config.lib.session.sessionSlice;
                        wantedBy = [ "graphical-session.target" ];
                    };

                    preserveSystem.directories = lib.singleton {
                        directory = "/var/cache/tuigreet";
                        user = "greeter";
                        group = "greeter";
                        mode = "0755";
                    };
                };
        };
}
