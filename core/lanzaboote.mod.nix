{
    lanzaboote,
    ...
}:
{
    universal =
        {
            lib,
            config,
            pkgs,
            ...
        }:
        {
            imports = [ lanzaboote.nixosModules.lanzaboote ];

            # New install setup process:
            # Boot 1: Bios secure boot is disabled; Lanzaboote is enabled. Secure
            #         boot keys have already been generated in install script. Run `sbctl
            #         verify` to ensure EFI files have been signed. If not, reboot.
            # Boot into bios: Enable secure boot in "Setup Mode".
            # Boot 2: Enroll our keys as instructed in the docs.
            # Done
            environment.systemPackages = [ pkgs.sbctl ];

            # NOTE: Lanzaboote replaces systemd-boot with it's own systemd-boot which
            # is configured here. Lanzaboote inherits most config from the standard
            # systemd-boot configuration.
            boot.loader.systemd-boot.enable = lib.mkForce false;

            boot.lanzaboote = {
                enable = true;
                pkiBundle = "${lib.optionalString config.preservation.enable "/state"}/var/lib/sbctl";
            };

            preserveSystem.directories = [ "/var/lib/sbctl" ];
        };
}
