{
    universal =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        lib.mkMerge [
            # Backend
            {
                networking.networkmanager.enable = true;
                users.users.arakhor.extraGroups = [ "networkmanager" ];
                systemd.services.NetworkManager-wait-online.enable = false;
            }
            # DNS
            {
                services.resolved.enable = true;
                networking.networkmanager.dns = "systemd-resolved";
                systemd.services.systemd-resolved.stopIfChanged = false;
                networking.nameservers = [
                    "1.1.1.1"
                    "1.0.0.1"
                    "2606:4700:4700::1111"
                    "2606:4700:4700::1001"
                ];
            }
            # mDNS
            {
                services.avahi = {
                    enable = true;
                    publish = {
                        enable = true;
                        addresses = true;
                    };
                    nssmdns4 = true;
                    nssmdns6 = true;
                };
            }
            # DHCP
            {
                networking.useDHCP = false;
                networking.dhcpcd.enable = false;
            }
            # Firewall
            {
                networking.firewall.enable = true;
                networking.firewall.allowPing = true;
                networking.firewall.logRefusedConnections = false;
                networking.nftables.enable = true;
            }
            # WiFi
            {
                networking.networkmanager.wifi = {
                    # backend = "iwd";
                    powersave = true;
                };

                boot.extraModprobeConfig = ''
                    options cfg80211 ieee80211_regdom="${config.locale.regulatory-domain}"
                '';

                preserveSystem.directories = [
                    {
                        directory = "/etc/NetworkManager/system-connections";
                        mode = "0700";
                    }
                ];
            }
        ];
}
