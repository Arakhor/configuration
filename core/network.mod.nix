{
    universal =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        lib.mkMerge [
            # DNS
            {
                services.resolved.enable = true;
                networking.networkmanager.dns = "systemd-resolved";
                systemd.services.systemd-resolved.stopIfChanged = false;
            }

            # mDNS
            # {
            #     services.avahi = {
            #         enable = true;
            #         publish = {
            #             enable = true;
            #             addresses = true;
            #         };
            #         nssmdns4 = true;
            #         nssmdns6 = true;
            #     };
            # }

            # Firewall
            {
                networking.firewall.enable = true;
                networking.firewall.allowPing = true;
                networking.firewall.logRefusedConnections = false;
                networking.nftables.enable = true;
            }

            # Backend
            {
                networking.useDHCP = false;
                networking.dhcpcd.enable = false;

                networking.networkmanager.enable = true;

                systemd.network.wait-online.enable = false;
                systemd.services.NetworkManager-wait-online.enable = false;
                users.users.arakhor.extraGroups = [ "networkmanager" ];
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
