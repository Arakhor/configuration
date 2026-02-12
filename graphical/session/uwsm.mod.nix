let
    module =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            inherit (lib)
                mkForce
                getExe'
                concatMapAttrs
                mkOption
                types
                ;

            cfg = config.programs.uwsm;
        in
        {
            options.programs.uwsm = {
                desktopNames = mkOption {
                    type = with types; listOf str;
                    internal = true;
                    default = [ ];
                    description = ''
                        List of desktop names to create drop-in overrides for. Should be the
                        exact case-sensitive name used in the .desktop file.
                    '';
                };

                sessionVariables = mkOption {
                    type =
                        with types;
                        attrsOf (
                            lazyAttrsOf (oneOf [
                                str
                                int
                                path
                            ])
                        );
                    default = { };
                    example = {
                        hyprland = {
                            HYPRCURSOR_SIZE = 24;
                        };
                        common = {
                            NIXOS_OZONE_WL = 1;
                        };
                    };

                };

                appUnitOverrides = mkOption {
                    type = with types; attrsOf lines;
                    default = { };
                    # apply = v: (optionalAttrs home-manager.enable homeUwsm.appUnitOverrides) // v;
                    description = ''
                        Attribute set of unit overrides. Attribute name should be the unit
                        name without the app-''${desktop} prefix. Attribute value should be
                        the multiline unit string.
                    '';
                    example = {
                        "discord-.scope" = ''
                            [Scope]
                            KillMode=mixed
                        '';

                        "steam@.service" = ''
                            [Service]
                            ...
                        '';
                    };
                };

                fumon.enable = mkOption {
                    type = types.bool;
                    default = true;
                    description = ''
                        Whether to enable Fumon service monitor. Warning: can cause CPU
                        spikes when launching units so probably best to disable on low
                        powered devices and laptops.
                    '';
                };
            };

            config = {
                environment = {
                    systemPackages = [ pkgs.app2unit ];
                    sessionVariables.APP2UNIT_SLICES = "a=app-graphical.slice b=background-graphical.slice s=session-graphical.slice";
                    # Even though I use the -t service flag pretty much everywhere in my
                    # config still keep the default behaviour as scope because this is
                    # generally how apps should be launched if we interactively run `app2unit
                    # app.desktop` in a terminal. Launching with a keybind, launcher or
                    # script should run the the app in a service since there's no value in
                    # process or input/output inheritance in these cases.
                    sessionVariables.APP2UNIT_TYPE = "scope";
                };

                systemd.user.services.fumon = {
                    enable = cfg.fumon.enable;
                    wantedBy = [ "graphical-session.target" ];
                    environment.PATH = mkForce null; # reason explained in desktop/default.nix
                    serviceConfig.ExecStart = [
                        "" # to replace original ExecStart
                        (getExe' config.programs.uwsm.package "fumon")
                    ];
                };

                maid-users.file.xdg_config = lib.concatMapAttrs (
                    desktop: vars:
                    lib.optionalAttrs (vars != { }) {
                        "uwsm/env${lib.optionalString (desktop != "common") "-${desktop}"}".text = lib.shell.exportAll vars;
                    }
                ) cfg.sessionVariables;

                systemd.user.units = concatMapAttrs (
                    unitName: text:
                    builtins.foldl' (
                        acc: desktop:
                        acc
                        // {
                            "app-${desktop}-${unitName}" = {
                                inherit text;
                                overrideStrategy = "asDropin";
                            };
                        }
                    ) { } cfg.desktopNames
                ) cfg.appUnitOverrides;
            };
        };
in
{ sources, ... }:
{
    graphical = {
        imports = [ module ];
        programs.uwsm.enable = true;

        nixpkgs.overlays = [
            (_: prev: {
                uwsm = prev.uwsm.overrideAttrs {
                    inherit (sources.uwsm) version;
                    src = sources.uwsm;
                };

                app2unit = prev.app2unit.overrideAttrs {
                    inherit (sources.app2unit) version;
                    src = sources.app2unit;
                };
            })
        ];
    };
}
