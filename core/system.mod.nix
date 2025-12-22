{
  universal =
    { lib, pkgs, ... }:
    {
      imports = [ (lib.mkAliasOptionModule [ "packages" ] [ "environment" "systemPackages" ]) ];

      system.stateVersion = "25.11";
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
      nixpkgs.config.allowUnfree = true;

      programs.nix-ld.enable = true;

      services.earlyoom = {
        enable = lib.mkDefault true;
        enableNotifications = true;
      };

      environment.sessionVariables = {
        XDG_CACHE_HOME = "$HOME/.cache";
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_STATE_HOME = "$HOME/.local/state";
      };
    };
}
