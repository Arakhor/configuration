{ preservation, ... }:
{
  universal =
    { lib, ... }:
    {
      imports = [
        preservation.nixosModules.default

        (lib.mkAliasOptionModule [ "preserveSystem" ] [ "preservation" "preserveAt" "/persist" ])

        (lib.mkAliasOptionModule
          [ "preserveHome" ]
          [ "preservation" "preserveAt" "/persist" "users" "arakhor" ]
        )
      ];

      preservation.enable = true;
      fileSystems."/persist".neededForBoot = true;
      boot.initrd.systemd.enable = true;

      preserveSystem = {
        directories = [
          "/var/log"
          "/var/lib/systemd/coredump"
          "/var/lib/systemd/rfkill"
          "/var/lib/systemd/timers"
          {
            directory = "/var/lib/nixos";
            inInitrd = true;
          }
          {
            directory = "/var/lib/private";
            mode = "0700";
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
