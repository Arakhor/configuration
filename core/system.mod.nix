{ chaotic, ... }:
{
    universal =
        { pkgs, lib, ... }:
        {
            imports = [ chaotic.nixosModules.default ];

            system.stateVersion = "25.11";
            nixpkgs.config.allowUnfree = true;

            boot.kernelPackages = pkgs.linuxPackages_cachyos;

            zramSwap = {
                enable = lib.mkDefault true;
                priority = lib.mkDefault 100;
                memoryPercent = lib.mkDefault 50;
                algorithm = lib.mkDefault "zstd";
            };

            services.earlyoom = {
                enable = lib.mkDefault true;
                extraArgs = lib.mkDefault [
                    "-M"
                    "409600,307200"
                    "-S"
                    "409600,307200"
                ];
            };

            environment.sessionVariables = {
                XDG_CACHE_HOME = "$HOME/.cache";
                XDG_CONFIG_HOME = "$HOME/.config";
                XDG_DATA_HOME = "$HOME/.local/share";
                XDG_STATE_HOME = "$HOME/.local/state";
            };
        };
}
