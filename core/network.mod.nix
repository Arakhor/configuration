{
  universal =
    { config, ... }:
    {
      networking.firewall.allowPing = true;
      networking.firewall.logRefusedConnections = false;

      systemd.network.enable = true;
      systemd.network.wait-online.enable = false;
      networking.useNetworkd = true;

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

      systemd.services.systemd-networkd.stopIfChanged = false;

      preserveSystem.directories = [
        {
          directory = "/var/lib/iwd";
          mode = "0700";
        }
      ];

      networking.wireless = {
        userControlled.enable = true;
        scanOnLowSignal = true;
        allowAuxiliaryImperativeNetworks = true;
        iwd = {
          enable = true;
          settings = {
            General.AddressRandomization = "network";
            # https://github.com/nixos/nixpkgs/issues/454655
            DriverQuirks.DefaultInterface = "";
          };
        };
      };
    };
}
