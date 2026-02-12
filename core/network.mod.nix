{
    universal =
        {
            config,
            pkgs,
            ...
        }:
        {
            networking = {
                useNetworkd = true;
                useDHCP = false;
                wireless.iwd = {
                    enable = true;
                    settings.General.EnableNetworkConfiguration = false;
                };
                firewall.enable = true;
                nftables.enable = true;
            };

            services = {
                resolved.enable = true;
                avahi = {
                    enable = true;
                    nssmdns4 = true;
                    openFirewall = true;
                };
            };

            systemd.network = {
                enable = true;
                wait-online.enable = false;
                networks = {
                    "10-wifi" = {
                        matchConfig.Name = "wl*";
                        networkConfig = {
                            DHCP = "yes";
                            IPv6PrivacyExtensions = "yes";
                        };
                    };

                    "20-wired" = {
                        matchConfig.Name = "en*";
                        networkConfig = {
                            DHCP = "yes";
                            IPv6PrivacyExtensions = "yes";
                        };
                    };
                };
            };

            boot.extraModprobeConfig = ''
                options cfg80211 ieee80211_regdom="${config.locale.regulatory-domain}"
            '';

            maid-users.packages = [ pkgs.impala ];
            maid-users.file.xdg_desktop.impala = {
                name = "Impala";
                genericName = "Wifi Manager";
                exec = "xdg-terminal-exec --title=impala --app-id=impala impala";
                terminal = false;
                type = "Application";
                icon = "nm-device-wireless";
                categories = [ "System" ];
            };

            systemd.services.systemd-networkd.stopIfChanged = false;
            systemd.services.systemd-resolved.stopIfChanged = false;

            preserveSystem.directories = [
                {
                    directory = "/var/lib/iwd";
                    mode = "0700";
                }
            ];
        };
}
