{
  universal =
    { lib, nixosConfig, ... }:
    let
      inherit (lib) mkDefault;
    in
    {
      boot = {
        enableContainers = mkDefault false;
        initrd.systemd.enable = mkDefault true;
      };
      documentation = {
        info.enable = mkDefault false;
        nixos.enable = mkDefault false;
      };
      environment.defaultPackages = mkDefault [ ];
      services.userborn.enable = mkDefault true;
      services.userborn.passwordFilesLocation = "/var/lib/nixos";
      programs = {
        command-not-found.enable = mkDefault false;
        less.lessopen = mkDefault null;
      };
      system = {
        etc.overlay.enable = mkDefault true;
        nixos-init.enable = mkDefault nixosConfig.system.etc.overlay.enable;

        tools.nixos-generate-config.enable = mkDefault false;
      };
    };
}
