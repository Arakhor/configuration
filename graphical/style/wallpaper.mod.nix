{ sources, ... }:
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
            # darkman = false;

            themeCache = ".cache/theme";
            wallpaperCache = ".cache/wallpaper";

            boolString = x: if x then "true" else "false";

            randomiseWallpaper =
                pkgs.writeNuScriptBin "randomise-wallpaper" # nu
                    ''
                        const WALLS = [${lib.concatMapStringsSep "\n" (w: ''"${w}"'') cfg.randomise.wallpapers}]

                        let cached_wallpaper = (
                            try {
                                open ($nu.home-dir)/${wallpaperCache}
                                | from json
                                | get name
                            }
                        )

                        let wallpaper = $WALLS
                            | where (($it | path basename) != $cached_wallpaper )
                            | get -o (random int 0..($in | length))
                            | default "${cfg.default}"

                        {
                            name: ($wallpaper | path basename)
                            store-path: $wallpaper
                        }
                        | to json
                        | save -f ($nu.home-dir)/${wallpaperCache}
                    '';

            setWallpaper =
                let
                    hooksAfter = lib.mapAttrsToList (_: v: v.hooks.after) config.style.dynamic.templates;
                    hooksBefore = lib.mapAttrsToList (_: v: v.hooks.before) config.style.dynamic.templates;
                in
                pkgs.writeNuScriptBin "set-wallpaper" # nu
                    ''
                        const MATUGEN = ${boolString config.style.dynamic.enable}
                        const RANDOMISE = ${boolString cfg.randomise.enable}

                        let wallpaper = if $RANDOMISE {
                            if not (($nu.home-dir)/${wallpaperCache} | path exists) {
                                systemctl start --user randomise-wallpaper.service
                            }
                            open ($nu.home-dir)/${wallpaperCache}
                            | from json
                            | get store-path  
                        } else { "${cfg.default}" }

                        try {
                            for i in 0..4 {
                                try {
                                    ${cfg.setWallpaperCommand} $wallpaper
                                    if $MATUGEN {
                                        ${lib.concatLines hooksBefore}

                                        ln -sfT ($env.XDG_STATE_HOME)/themes/($wallpaper | path basename) ($nu.home-dir)/${themeCache}

                                        ${lib.concatLines hooksAfter}
                                    }
                                    break
                                } catch {
                                    sleep 0.5sec
                                }
                            }
                        } catch {
                            print "Failed to set wallpaper after 5 attempts"
                            return 1
                        }
                    '';
        in
        {
            options.style.wallpaper = {
                enable = mkOption {
                    type = types.bool;
                    readOnly = true;
                    default = cfg.setWallpaperCommand != null;
                };

                default = mkOption {
                    type = types.path;
                    default = "${sources.qhd-wallpapers}/pixel/wallhaven-zyqx1v-pixel.png";
                    description = ''
                        The default wallpaper to use if randomise is disabled.
                    '';
                };

                wallpaperUnit = mkOption {
                    type = types.str;
                    example = "swww.service";
                    description = ''
                        Unit of the wallpaper manager.
                    '';
                };

                randomise = {
                    enable = mkEnableOption "random wallpaper selection" // {
                        default = cfg.randomise.wallpapers != [ ];
                    };

                    frequency = mkOption {
                        type = types.str;
                        default = "*:0/15";
                        description = ''
                            How often to randomly select a new wallpaper. Format is for the
                            systemd timer OnCalendar option.
                        '';
                        example = "weekly";
                    };

                    wallpapers = lib.mkOption {
                        description = "Collection of wallpapers used for random switching.";
                        type = with lib.types; listOf path;
                        example = [
                            /home/user/wallpapers/mountain.jpg
                            /home/user/wallpapers/ocean.jpg
                        ];
                        default = "${sources.qhd-wallpapers}/pixel" |> lib.filesystem.listFilesRecursive;
                    };
                };

                setWallpaperCommand = mkOption {
                    type = with types; nullOr str;
                    default = null;
                    # apply = v: if v != null then pkgs.writers.writeNu "set-wallpaper" v else null;
                    description = ''
                        Command for setting the wallpaper. 
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
                            ];
                            # ++ optional darkman "darkman.service";
                            requires = [ cfg.wallpaperUnit ];
                            environment.PATH = lib.mkForce null;
                            unitConfig.X-SwitchMethod = "keep-old";

                            serviceConfig = {
                                Type = "oneshot";
                                ExecStart = (getExe setWallpaper);
                            };

                            wantedBy = [ cfg.wallpaperUnit ];
                        };
                    }

                    (mkIf (!cfg.randomise.enable) {
                        maid-users.file.xdg_cache."theme/wallpaper".source = cfg.default;
                    })

                    (mkIf cfg.randomise.enable {
                        preserveHome.files = [ wallpaperCache ];

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
                                    ExecStart = (getExe randomiseWallpaper);
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
