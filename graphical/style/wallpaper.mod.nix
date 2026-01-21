{
    graphical =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            inherit (lib)
                mkIf
                mkMerge
                mkOption
                mkEnableOption
                getExe
                optional
                types
                ;

            cfg = config.style.wallpaper;

            # TODO:
            darkman = false;

            setWallpaper =
                pkgs.writers.writeNuBin "set-wallpaper" # nu
                    '''';

            randomiseWallpaper =
                pkgs.writers.writeNuBin "set-wallpaper" # nu
                    '''';

        in
        {
            options.style.wallpaper = {
                enable = mkOption {
                    type = types.bool;
                    readOnly = true;
                    default = cfg.setWallpaperScript != null;
                };

                default = mkOption {
                    type = types.package;
                    # default = TODO ;
                    description = ''
                        The default wallpaper to use if randomise is disabled.
                    '';
                };

                dark = mkOption {
                    type = types.package;
                    default = cfg.defaults.default;
                    description = ''
                        The dark theme wallpaper to use if randomise is disabled and
                        darkman is enabled.
                    '';
                };

                light = mkOption {
                    type = types.package;
                    default = cfg.defaults.default;
                    description = ''
                        The light theme wallpaper to use if randomise is disabled and
                        darkman is enabled.
                    '';
                };

                unit = mkOption {
                    type = types.str;
                    example = "swww.service";
                    description = ''
                        Unit of the wallpaper manager.
                    '';
                };

                randomise = {
                    enable = mkEnableOption "random wallpaper selection";

                    frequency = mkOption {
                        type = types.str;
                        default = "weekly";
                        description = ''
                            How often to randomly select a new wallpaper. Format is for the
                            systemd timer OnCalendar option.
                        '';
                        example = "monthly";
                    };
                };

                setWallpaperScript = mkOption {
                    type = with types; nullOr str;
                    default = null;
                    apply = v: if v != null then pkgs.writers.writeNu "set-wallpaper" v else null;
                    description = ''
                        Command for setting the wallpaper. First argument passed to the
                        script will be a path to the wallpaper img.
                    '';
                };
            };

            config =
                [
                    {
                        maid-users.systemd.services.set-wallpaper = {
                            description = "Set the desktop wallpaper";
                            after = [
                                cfg.wallpaperUnit
                            ]
                            ++ optional cfg.randomise.enable "randomise-wallpaper.service"
                            ++ optional darkman.enable "darkman.service";
                            requires = [ cfg.wallpaperUnit ];

                            unitConfig.X-SwitchMethod = "keep-old";

                            serviceConfig = {
                                Type = "oneshot";
                                ExecStart = getExe setWallpaper;
                            };

                            wantedBy = [ cfg.wallpaperUnit ];
                        };

                    }

                    (mkIf cfg.randomise.enable {
                        preserveHome.directories = [ ".cache/wallpaper" ];

                        programs.nushell.shellAliases = {
                            set-wallpaper = "systemctl start --user set-wallpaper";
                            randomise-wallpaper = "systemctl start --user randomise-wallpaper";
                        };

                        # ns.desktop.darkman.switchScripts.wallpaper = _: ''
                        #     systemctl start --user set-wallpaper
                        # '';

                        maid-users.systemd = {
                            services.randomise-wallpaper = {
                                description = "Randomise the desktop wallpaper";
                                before = [ "set-wallpaper.service" ];
                                wants = [ "set-wallpaper.service" ];
                                unitConfig.X-SwitchMethod = "keep-old";

                                serviceConfig = {
                                    Type = "oneshot";
                                    ExecStart = [ (getExe randomiseWallpaper) ];
                                };
                            };

                            timers.randomise-wallpaper = {
                                description = "Timer for randomising the desktop wallpaper";

                                unitConfig.X-SwitchMethod = "keep-old";

                                timerConfig = {
                                    OnCalendar = cfg.randomise.frequency;
                                    Persistent = true;
                                };

                                wantedBy = [ "timers.target" ];
                            };
                        };
                    })
                ]
                |> mkMerge
                |> mkIf cfg.enable;
        };

}
