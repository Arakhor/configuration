{
  zeph.disko.devices =
    { lib, ... }:
    let
      hostname = "zeph";
    in
    {
      disk = lib.genAttrs [ "0" "1" ] (i: {
        type = "disk";
        device = "/dev/nvme${i}n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00";
              content = {
                type = "mdraid";
                name = "boot";
              };
            };

            mdadm = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid1";
              };
            };
          };
        };
      });

      mdadm = {
        boot = {
          type = "mdadm";
          level = 1;
          metadata = "1.0";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        root = {
          type = "mdadm";
          level = 1;
          metadata = "1.2";
          content = {
            type = "luks";
            name = "${hostname}-crypt";

            askPassword = true;
            settings = {
              allowDiscards = true;
              bypassWorkqueues = true;
            };

            content = {
              type = "lvm_pv";
              vg = "${hostname}-vg";
            };
          };
        };
      };

      lvm_vg."${hostname}-vg" = {
        type = "lvm_vg";
        lvs = {
          swap = {
            size = "96G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };

          nix = {
            size = "200G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/nix";
              mountOptions = [ "noatime" ];
            };
          };

          state = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/state";
              mountOptions = [ "noatime" ];
            };
          };
        };
      };

      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = [
          "mode=755"
          "size=48g"
        ];
      };
    };
}
