{
    base =
        {
            config,
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
            environment.systemPackages = [
                pkgs.uutils-coreutils-noprefix
                pkgs.uutils-procps
                pkgs.uutils-util-linux
                pkgs.uutils-findutils

                pkgs.w3m-nographics # needed for the manual anyway
                pkgs.testdisk # useful for repairing boot problems
                pkgs.ms-sys # for writing Microsoft boot sectors / MBRs
                pkgs.efibootmgr
                pkgs.efivar
                pkgs.parted
                pkgs.gptfdisk
                pkgs.ddrescue
                pkgs.ccrypt
                pkgs.cryptsetup # needed for dm-crypt volumes

                # Some networking tools.
                pkgs.fuse
                pkgs.fuse3
                pkgs.sshfs-fuse
                pkgs.socat
                pkgs.screen
                pkgs.tcpdump
                pkgs.wget

                # Hardware-related tools.
                pkgs.sdparm
                pkgs.hdparm
                pkgs.smartmontools # for diagnosing hard disks
                pkgs.pciutils
                pkgs.usbutils
                pkgs.nvme-cli

                # Some compression/archiver tools.
                pkgs.unzip
                pkgs.zip
            ];
        };
}
