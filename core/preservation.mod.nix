{ preservation, ph, ... }:
{
    universal =
        { lib, ... }:
        {
            imports = [
                preservation.nixosModules.default
                ph.nixosModules.default

                (lib.mkAliasOptionModule [ "preserveSystem" ] [ "preservation" "preserveAt" "/persist" ])

                (lib.mkAliasOptionModule
                    [ "preserveHome" ]
                    [ "preservation" "preserveAt" "/persist" "users" "arakhor" ]
                )
            ];

            preservation.enable = true;
            fileSystems."/persist".neededForBoot = true;
            boot.initrd.systemd.enable = true;
            programs.ph.enable = true;

            preserveSystem = {
                commonMountOptions = [
                    "x-gvfs-hide"
                    "x-gdu.hide"
                ];

                directories = [
                    "/srv"
                    "/var/log"
                    "/var/tmp"
                    "/var/lib/systemd"
                    "/var/lib/nixos"
                ];

                files = [
                    {
                        file = "/etc/machine-id";
                        inInitrd = true;
                    }
                    "/etc/adjtime"
                ];
            };

            preserveHome = {
                directories = [
                    "Downloads"
                    "Pictures"
                    "Music"
                    "Videos"

                    ".cache/nix"
                    ".local/share/systemd"
                ];
            };

            systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
        };
}
