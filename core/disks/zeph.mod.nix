{
    zeph.disko.devices = {
        nodev."/" = {
            fsType = "tmpfs";
            mountOptions = [
                "defaults"
                "size=32G"
                "mode=0755"
            ];
        };
        disk.nvme0n1 = {
            type = "disk";
            device = "/dev/nvme0n1";
            content = {
                type = "gpt";
                partitions = {
                    ESP = {
                        label = "boot";
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
                    raid = {
                        size = "100%";
                        label = "raid0";
                    };
                };
            };
        };
        disk.nvme1n1 = {
            type = "disk";
            device = "/dev/nvme1n1";
            content = {
                type = "gpt";
                partitions = {
                    raid = {
                        size = "100%";
                        label = "raid1";
                        content = {
                            type = "btrfs";
                            extraArgs = [
                                "-d"
                                "raid0"
                                "/dev/disk/by-partlabel/raid0"
                                "/dev/disk/by-partlabel/raid1"
                                "-L"
                                "nixos"
                                "-f"
                            ];
                            subvolumes = {
                                "@nix" = {
                                    mountpoint = "/nix";
                                    mountOptions = [
                                        "subvol=nix"
                                        "compress=zstd:1"
                                        "noatime"
                                        "ssd"
                                    ];
                                };
                                "@state" = {
                                    mountpoint = "/state";
                                    mountOptions = [
                                        "subvol=state"
                                        "compress=zstd"
                                        "noatime"
                                        "ssd"
                                    ];
                                };
                            };
                        };
                    };
                };
            };
        };

    };
}
