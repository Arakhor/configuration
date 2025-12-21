{
  nixos-facter-modules,
  disko,
  ...
}:
{
  universal =
    { config, lib, ... }:
    {
      imports = [
        disko.nixosModules.disko
        nixos-facter-modules.nixosModules.facter
      ];

      services.fwupd.enable = true;
      preserveSystem.directories = [ "/var/lib/fwupd" ];

      services.power-profiles-daemon.enable = true;

      services.upower = {
        enable = lib.mkDefault (config.facter.report.hardware.system.form_factor == "laptop");
        percentageLow = 15;
        percentageCritical = 5;
        percentageAction = 3;
      };
    };

  xps = {
    networking.hostName = "xps";
    facter.reportPath = ./hardware-scans/xps.json;
    services.fstrim.enable = true;
    # Make hibernation images as small as possible
    systemd.tmpfiles.rules = [ "w /sys/power/image_size - - - - 0" ];
  };

  zeph = {
    networking.hostName = "zeph";
    facter.reportPath = ./hardware-scans/xps.json;
  };
}
