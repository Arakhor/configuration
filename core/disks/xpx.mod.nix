{
    xps.disko.devices = {
        disk.nixos = {
            type = "disk";
            device = "/dev/nvme0n1";
            content = {
                type = "gpt";
                partitions = {
                    esp = {
                        size = "512M";
                        type = "EF00";
                        content = {
                            type = "filesystem";
                            format = "vfat";
                            mountpoint = "/boot";
                            mountOptions = [ "umask=0077" ];
                        };
                    };

                    luks = {
                        size = "100%";
                        content = {
                            type = "luks";
                            name = "xps-crypted";

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
                                vg = "xps-nixos";
                            };
                        };
                    };
                };
            };
        };

        lvm_vg."xps-nixos" = {
            type = "lvm_vg";
            lvs = {
                swap = {
                    size = "8G";
                    content = {
                        type = "swap";
                        resumeDevice = true;
                    };
                };

                nix = {
                    size = "100G";
                    content = {
                        type = "filesystem";
                        format = "ext4";
                        mountpoint = "/nix";
                        mountOptions = [ "noatime" ];
                    };
                };

                persist = {
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
