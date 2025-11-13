{
    universal =
        { config, ... }:
        {

            networking.networkmanager.enable = true;
            # networking.useNetworkd = true;
            networking.firewall.enable = true;

            users.users.arakhor.extraGroups = [ "networkmanager" ];

            systemd.network.enable = true;
            systemd.network.wait-online.enable = false;
            systemd.services.NetworkManager-wait-online.enable = false;
            # systemd.services.systemd-networkd.stopIfChanged = false;
            # systemd.services.systemd-resolved.stopIfChanged = false;

            services.resolved.enable = false;
            environment.etc."resolv.conf".text = ''
                ${builtins.concatStringsSep "\n" (map (ns: "nameserver ${ns}") config.networking.nameservers)}
                options edns0
            '';

            networking.nameservers = [
                "1.1.1.1"
                "1.0.0.1"
                "2606:4700:4700::1111"
                "2606:4700:4700::1001"
            ];

            preserveSystem.directories = [
                "/etc/NetworkManager/system-connections"
                "/var/lib/NetworkManager"
            ];
        };
}
