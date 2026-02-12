{
    base =
        {
            lib,
            pkgs,
            ...
        }:
        {
            nixpkgs.config.allowUnfree = true;
            system.stateVersion = lib.trivial.release;

            security.sudo-rs = {
                enable = true;
                execWheelOnly = true;
                wheelNeedsPassword = false;
            };

            # Disable watchdog
            boot.extraModprobeConfig = ''
                blacklist iTCO_wdt
                blacklist iTCO_vendor_support
                blacklist sp5100_tco
            '';
            boot.kernelParams = [
                "nowatchdog"
                "nmi_watchdog=0"
            ];
            systemd.settings.Manager = {
                RebootWatchdogSec = lib.mkForce null;
                RuntimeWatchdogSec = lib.mkForce null;
                KExecWatchdogSec = lib.mkForce null;
            };

            # Include some utilities that are useful for installing or repairing
            # the system.
            environment.systemPackages = with pkgs; [
                uutils-coreutils-noprefix
                uutils-procps
                uutils-findutils
                uutils-hostname
                uutils-login
                uutils-tar
                uutils-acl
                uutils-sed
                uutils-util-linux

                toybox
                w3m-nographics # needed for the manual anyway
                testdisk # useful for repairing boot problems
                ms-sys # for writing Microsoft boot sectors / MBRs
                efibootmgr
                efivar
                parted
                gptfdisk
                ddrescue
                ccrypt
                cryptsetup # needed for dm-crypt volumes

                # Some networking tools.
                fuse
                fuse3
                sshfs-fuse
                socat
                screen
                tcpdump
                wget

                # Hardware-related tools.
                sdparm
                hdparm
                smartmontools # for diagnosing hard disks
                pciutils
                usbutils
                nvme-cli
                mesa-demos

                # Some compression/archiver tools.
                unzip
                zip
            ];
        };
}
