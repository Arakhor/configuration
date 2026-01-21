{
    graphical =
        {
            pkgs,
            lib,
            config,
            ...
        }:
        let
            inherit (lib) mkIf types;

            cfg = config.services.darkman;

            yamlFormat = pkgs.formats.yaml { };

            generateScripts =
                folder:
                lib.mapAttrs' (
                    k: v: {
                        name = "${folder}/${k}";
                        value = {
                            source = if builtins.isPath v || lib.isDerivation v then v else pkgs.writeShellScript "${k}" v;
                        };
                    }
                );
        in
        {
            options.services.darkman = {
                enable = lib.mkEnableOption ''
                    darkman, a tool that automatically switches dark-mode on and off based on
                    the time of the day'';

                package = lib.mkPackageOption pkgs "darkman" { nullable = true; };

                settings = lib.mkOption {
                    type = types.submodule { freeformType = yamlFormat.type; };
                    default = { };
                    example = lib.literalExpression ''
                        {
                          lat = 52.3;
                          lng = 4.8;
                          usegeoclue = true;
                        }
                    '';
                    description = ''
                        Settings for the {command}`darkman` command. See
                        <https://darkman.whynothugo.nl/#CONFIGURATION> for details.
                    '';
                };

                switchScripts = lib.mkOption {
                    type = types.attrsOf (types.functionTo types.lines);
                    default = { };
                    example = lib.literalExpression ''
                        {
                          gtk-theme = mode: '''
                            ''${pkgs.dconf}/bin/dconf write \
                                /org/gnome/desktop/interface/color-scheme "'prefer-''${mode}'"
                          ''';
                          my-python-script = mode: pkgs.writers.writePython3 "my-python-script-''${mode}" { } '''
                            print('Switching to ''${mode} mode!')
                          ''';
                        }
                    '';
                    description = ''
                        Attribute set of functions that accept a string "dark" or "light"
                        and return lines of a Bash shell script to run when switching to that mode.
                        For each function, scripts are generated in both
                        `dark-mode.d/` and `light-mode.d/` directories, passing the
                        appropriate mode argument.
                    '';
                };
            };

            config = mkIf cfg.enable {
                environment.systemPackages = lib.mkIf (cfg.package != null) [ cfg.package ];

                xdg.portal = {
                    config.common."org.freedesktop.impl.portal.Settings" = [ "darkman" ];
                    extraPortals = [ cfg.package ];
                };

                maid-users.file = {
                    xdg_config."darkman/config.yaml" = mkIf (cfg.settings != { }) {
                        source = yamlFormat.generate "darkman-config.yaml" cfg.settings;
                    };

                    xdg_data =
                        let
                            darkScripts = lib.mapAttrs (_: script: script "dark") cfg.switchScripts;
                            lightScripts = lib.mapAttrs (_: script: script "light") cfg.switchScripts;
                        in
                        lib.mkMerge [
                            (generateScripts "dark-mode.d" darkScripts)
                            (generateScripts "light-mode.d" lightScripts)
                        ];
                };

                maid-users.systemd.services.darkman = lib.mkIf (cfg.package != null) {
                    description = "Darkman system service";
                    documentation = [ "man:darkman(1)" ];
                    partOf = [ "graphical-session.target" ];
                    bindsTo = [ "graphical-session.target" ];

                    unitConfig.X-Restart-Triggers = mkIf (cfg.settings != { }) [
                        "${config.maid-users.file.xdg_config."darkman/config.yaml".source}"
                    ];

                    serviceConfig = {
                        Type = "dbus";
                        BusName = "nl.whynothugo.darkman";
                        ExecStart = "${lib.getExe cfg.package} run";
                        Restart = "on-failure";
                        TimeoutStopSec = 15;
                        Slice = "background.slice";
                    };

                    wantedBy = lib.mkDefault [ "graphical-session.target" ];
                };
            };
        };
}
