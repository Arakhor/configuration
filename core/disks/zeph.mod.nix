{
  zeph.disko.devices = {
    disk.disk1 = {
      type = "disk";
      device = "/dev/nvme0n1";
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
      device = "/dev/nvme1n1";
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

    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "defaults"
        "mode=755"
        "size=32g"
      ];
    };
  };
}
