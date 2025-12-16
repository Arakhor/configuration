{
  universal =
    { config, pkgs, ... }:
    {
      programs.localsend.enable = true;

      # to make `dig` & other utils available
      environment.systemPackages = [ pkgs.bind.dnsutils ];

      networking.firewall.enable = true;
      networking.firewall.allowPing = true;
      networking.firewall.logRefusedConnections = false;

      networking.useNetworkd = true;
      systemd.network.enable = true;
      systemd.network.wait-online.enable = false;
      systemd.services.systemd-networkd.stopIfChanged = false;

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

      services.avahi = {
        enable = true;
        # publish the local machines IP
        publish = {
          enable = true;
          addresses = true;
        };
        # resolve .local domains via avahi discovery
        nssmdns4 = true;
        nssmdns6 = true;
      };

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

      preserveSystem.directories = [
        {
          directory = "/var/lib/iwd";
          mode = "0700";
        }
      ];
    };
}
