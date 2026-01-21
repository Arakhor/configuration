{
    universal =
        { config, ... }:
        {
            boot = {
                enableContainers = false;
                initrd.systemd.enable = true;
            };
            documentation = {
                info.enable = false;
                nixos.enable = false;
            };
            environment.defaultPackages = [ ];
            services.userborn.enable = true;
            services.userborn.passwordFilesLocation = "/var/lib/nixos";
            programs = {
                command-not-found.enable = false;
                less.lessopen = null;
            };
            system = {
                etc.overlay.enable = true;
                # etc.overlay.mutable = false;
                nixos-init.enable = config.system.etc.overlay.enable;

                tools.nixos-generate-config.enable = false;
            };
        };
}
