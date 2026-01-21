{
    graphical =
        {
            pkgs,
            lib,
            config,
            ...
        }:
        {
            environment.systemPackages = [
                pkgs.discord
            ];

            # Electron apps core dump on exit with the default KillMode control-group.
            # This causes compositor exit to get delayed so just aggressively kill
            # these apps with Killmode mixed.
            programs.uwsm.appUnitOverrides = lib.genAttrs [ "vesktop@.service" "discord@.service" ] (_: ''
                [Service]
                KillMode=mixed
            '');

            preserveHome.directories = [
                ".config/discord"
                ".config/vesktop"
            ];
        };
}
