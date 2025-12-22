{
  zeph.disko.devices =
    { lib, ... }:
    let
      hostname = "zeph";
    in
    {
      # Devices will be mounted and formatted in alphabetical order, and btrfs can only mount raids
      # when all devices are present. So we define an "empty" luks device on the first disk,
      # and the actual btrfs raid on the second disk, and the name of these entries matters!
      disk.disk1 = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "96G";
              label = "swap";
              content = {
                type = "swap";
                resumeDevice = true; # allow hibernation
              };
            };
            crypt_p1 = {
              size = "100%";
              content = {
                type = "luks";
                name = "p1"; # device-mapper name when decrypted
                settings = {
                  allowDiscards = true;
                };
              };
            };
          };
        };
      };

      disk.disk2 = {
        type = "disk";
        device = "/dev/sdb";
        content = {
          type = "gpt";
          partitions = {
            crypt_p2 = {
              size = "100%";
              content = {
                type = "luks";
                name = "p2";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-d raid1"
                    "/dev/mapper/p1" # Use decrypted mapped device, same name as defined in disk1
                  ];
                  subvolumes = {
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "noatime"
                        "compress=zstd"
                      ];
                    };
                    "@state" = {
                      mountpoint = "/state";
                      mountOptions = [
                        "noatime"
                        "compress=zstd"
                      ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

  nodev."/" = {
    fsType = "tmpfs";
    mountOptions = [
      "defaults"
      "mode=755"
      "size=32g"
    ];
  };
}
