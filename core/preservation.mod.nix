{ preservation, ... }:
{
    universal =
        { lib, ... }:
        {
            imports = [
                preservation.nixosModules.default

                (lib.mkAliasOptionModule [ "preserveSystem" ] [ "preservation" "preserveAt" "/state" ])

                (lib.mkAliasOptionModule
                    [ "preserveHome" ]
                    [ "preservation" "preserveAt" "/state" "users" "arakhor" ]
                )
            ];

            config = {
                preservation.enable = true;
                fileSystems."/state".neededForBoot = true;
                boot.initrd.systemd.enable = true;

                preserveSystem = {
                    directories = [
                        "/var/lib"
                        "/var/log"
                        "/var/tmp"
                        {
                            directory = "/var/lib/nixos";
                            inInitrd = true;
                            mode = "0755";
                            user = "root";
                            group = "root";
                        }
                    ];

                    files = [
                        {
                            file = "/etc/machine-id";
                            inInitrd = true;
                        }
                        {
                            file = "/var/lib/systemd/random-seed";
                            how = "symlink";
                            inInitrd = true;
                            configureParent = true;
                        }
                    ];
                };

                preserveHome = {
                    commonMountOptions = [ "x-gvfs-hide" ];
                };

                systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
            };
        };
}
