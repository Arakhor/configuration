let
  username = "arakhor";
  hostname = "zeph";
  poolName = "${hostname}-zpool";
  pseudoRoot = "${hostname}-nixos";
in
{
  zeph.disko.devices = {
    disk = {
      "2TB-NVME-0" = {
        type = "disk";
        device = "/dev/nvme0";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              name = "boot";
              size = "1024M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = poolName;
              };
            };
          };
        };
      };

      "2TB-NVME-1" = {
        type = "disk";
        device = "/dev/nvme1";
        content = {
          type = "gpt";
          partitions.zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "${poolName}-1";
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
      ];
    };

    zpool =
      let
        rootFsOptions = {
          atime = "off";
          mountpoint = "none";
          xattr = "sa";
          acltype = "posixacl";
          compression = "lz4";
        };
      in
      {
        ${poolName} = {
          type = "zpool";
          options.ashift = "12";
          inherit rootFsOptions;

          datasets = {
            ${pseudoRoot}.type = "zfs_fs";

            "${pseudoRoot}/nix" = {
              type = "zfs_fs";
              mountpoint = "/nix";
              options.mountpoint = "legacy";
            };

            "${pseudoRoot}/state" = {
              type = "zfs_fs";
              options = {
                encryption = "aes-256-gcm";
                keyformat = "passphrase";
                keylocation = "prompt";
              };
            };

            "${pseudoRoot}/state/steam" = {
              type = "zfs_fs";
              mountpoint = "/state/home/${username}/.local/share/Steam";
              options.mountpoint = "legacy";
              options.recordsize = "1M";
            };

            "${pseudoRoot}/state/games" = {
              type = "zfs_fs";
              mountpoint = "/state/home/${username}/games";
              options.mountpoint = "legacy";
              options.recordsize = "1M";
            };

            "${pseudoRoot}/state/models" = {
              type = "zfs_fs";
              mountpoint = "/state/var/lib/private/ollama";
              options.mountpoint = "legacy";
              options.recordsize = "1M";
            };
          };
        };

        "${poolName}-1" = {
          type = "zpool";
          options.ashift = "12";
          inherit rootFsOptions;

          datasets = {
            ${pseudoRoot}.type = "zfs_fs";

            "${pseudoRoot}/state" = {
              type = "zfs_fs";
              mountpoint = "/state";
              options = {
                mountpoint = "legacy";
                encryption = "aes-256-gcm";
                keyformat = "passphrase";
                keylocation = "prompt";
              };
            };

            "${pseudoRoot}/state/videos" = {
              type = "zfs_fs";
              mountpoint = "/state/home/${username}/videos";
              options.mountpoint = "legacy";
              options.recordsize = "1M";
            };

            "${pseudoRoot}/state/pictures" = {
              type = "zfs_fs";
              mountpoint = "/state/home/${username}/pictures";
              options.mountpoint = "legacy";
              options.recordsize = "1M";
            };

            "${pseudoRoot}/state/music" = {
              type = "zfs_fs";
              mountpoint = "/state/home/${username}/music";
              options.mountpoint = "legacy";
              options.recordsize = "1M";
            };

            "${pseudoRoot}/state/downloads" = {
              type = "zfs_fs";
              mountpoint = "/state/home/${username}/downloads";
              options.mountpoint = "legacy";
              options.recordsize = "1M";
            };
          };
        };
      };
  };
}
