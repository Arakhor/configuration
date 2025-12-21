let
  username = "arakhor";
in
{
  zeph.disko.devices = {
    disk = {
      nvme0 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            raid = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "md0";
              };
            };
          };
        };
      };

      nvme1 = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions.raid = {
            size = "100%";
            content = {
              type = "mdraid";
              name = "md0";
            };
          };

        };
      };
    };

    mdadm.md0 = {
      type = "mdadm";
      level = 1;
      metadata = "1.2";
      content = {
        type = "gpt";
        partitions = {
          swap = {
            size = "80G"; # hibernation-safe for 64GB RAM
            content = {
              type = "luks";
              name = "cryptswap";
              settings.allowDiscards = true;
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
          };

          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptstate";
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = [
                  "-L"
                  "state"
                  "-m"
                  "single"
                  "-d"
                  "single"
                ];
                subvolumes = {
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };

                  "@state" = {
                    mountpoint = "/state";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "commit=120"
                    ];
                  };

                  "@state-steam" = {
                    mountpoint = "/state/home/${username}/.local/share/Steam";
                  };

                  "@state-games" = {
                    mountpoint = "/state/home/${username}/games";
                  };

                  "@state-videos" = {
                    mountpoint = "/state/home/${username}/videos";
                  };

                  "@state-music" = {
                    mountpoint = "/state/home/${username}/music";
                  };

                  "@state-pictures" = {
                    mountpoint = "/state/home/${username}/pictures";
                  };

                  "@state-downloads" = {
                    mountpoint = "/state/home/${username}/downloads";
                  };

                  "@state-models" = {
                    mountpoint = "/state/var/lib/private/ollama";
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
        "mode=755"
        "size=16G"
      ];
    };
  };
}
