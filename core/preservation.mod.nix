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

      preservation.enable = true;
      fileSystems."/state".neededForBoot = true;
      boot.initrd.systemd.enable = true;

      preserveSystem = {
        directories = [
          "/srv"
          "/var/log"
          "/var/tmp"
          "/var/lib/systemd"
          "/var/db/sudo/lectured"
          {
            directory = "/var/lib/nixos";
            inInitrd = true;
          }
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
        commonMountOptions = [ "x-gvfs-hide" ];
      };

      systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
    };
}
