{ lib, ... }:
let
  hostname = "zeph";
in
{
  zeph.disko.devices = {
    disk = lib.genAttrs [ "0" "1" ] (i: {
      type = "disk";
      device = "/dev/nvme${i}";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # for grub MBR
          };
          ESP = {
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
      raid1 = {
        type = "mdadm";
        level = 1;
        content = {
          type = "luks";
          name = "${hostname}-crypted";

          askPassword = true;
          settings = {
            allowDiscards = true; # enables trimming support
            bypassWorkqueues = true; # improves performance
            crypttabExtraOpts = [
              "tries=5"
              # We don't need to measure the volume key in a PCR but this
              # is needed to allow multiple tries of TPM pins
              # https://github.com/systemd/systemd/issues/32041
              "tpm2-measure-pcr=yes"
              # I think the above disables the cryptsetup token plugin (the prompt that
              # starts with "Please enter LUKS2 token PIN: ") so we've got to use native
              # systemd TPM pin unlock
              "tpm2-pin=yes"
              "tpm2-device=auto"
            ];
          };

          # https://www.man7.org/linux/man-pages/man8/cryptsetup-luksFormat.8.html
          extraFormatArgs = [
            "--type=luks2"
            "--use-random" # true randomness at the cost of blocking if there isn't enough entropy
          ];

          content = {
            type = "lvm_pv";
            vg = "${hostname}-nixos";
          };
        };
      };
    };

    lvm_vg."${hostname}-nixos" = {
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
        "defaults"
        "mode=755"
        "size=32g"
      ];
    };
  };
}
