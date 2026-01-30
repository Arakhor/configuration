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
                    default = 1.0;
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
                            gaps = 64;
                            background-color = "#000000";
                            border.active.color = "#ffffff30";
                            center-focused-column = "always";
                            default-column-width.proportion = config.login.tuigreet-width.proportion;
                        };
                    };

                    environment.sessionVariables.UWSM_SILENT_START = 2;

                    services.greetd = {
                        enable = true;
                        # useTextGreeter = true;
                        settings.default_session = {
                            # greetd should run as the greeter user otherwise it automatically logs
                            # in without prompting for password
                            user = "greeter";
                            command =
                                let
                                    niri = "/run/current-system/sw/bin/niri";
                                    ghostty = lib.getExe pkgs.ghostty;
                                    ghostty-config =
                                        (pkgs.runNuCommandLocal "config" { } /* nu */ ''
                                            open --raw ${config.users.users.arakhor.maid.file.xdg_config."ghostty/config".source}
                                            | str replace 'matugen' 'Material Ocean'
                                            | save $env.out
                                        '').outPath;
                                    tuigreet = lib.getExe pkgs.tuigreet;
                                in
                                builtins.concatStringsSep " " [
                                    niri
                                    "-c"
                                    niri-config
                                    "--"
                                    "/usr/bin/env"
                                    # shader cache for the Blazingly Fast Terminal Emulators
                                    "XDG_CACHE_HOME=/var/cache/tuigreet"
                                    ghostty
                                    "--config-file=${ghostty-config}"
                                    "-e"
                                    tuigreet
                                    "--time"
                                    "--remember"
                                    "--remember-session"
                                    "--asterisks"
                                    "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
                                    ";"
                                    "${niri} msg action quit"
                                ];
                        };
                    };

                    security = {
                        polkit.enable = true;
                        soteria.enable = true;
                        pam.services.greetd = {
                            enableGnomeKeyring = true;
                        };
                    };

                    systemd.user.services.polkit-soteria = {
                        environment.PATH = lib.mkForce null;
                        serviceConfig.Slice = config.lib.session.sessionSlice;
                        requisite = [ "graphical-session.target" ];
                        wantedBy = [ "graphical-session.target" ];
                        after = [ "graphical-session.target" ];
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
