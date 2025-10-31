{ nix-maid, ... }:
{
    universal =
        { lib, config, ... }:
        {
            imports = [
                nix-maid.nixosModules.default

                (lib.mkAliasOptionModule [ "home" ] [ "users" "users" "arakhor" "maid" ])
            ];

            users.mutableUsers = false;
            # sops.secrets."user/arakhor/password".neededForUsers = true;

            users.users.arakhor = {
                isNormalUser = true;
                description = "arakhor";
                extraGroups = [ "wheel" ];
                # hashedPasswordFile = config.sops.secrets."user/arakhor/password".path;
                hashedPassword = "$y$j9T$zx4TCrMTNKM4drj3Tqae2.$ntS.6gvtScUra.N8VK2ovxv4FHnz.Xlj4ucTr43.Sz/";
            };

            _module.args.nixosConfig = config;
            _module.args.homeConfig = config.home;
            home._module.args.nixosConfig = config;

            preserveHome.directories = [ ".local/state/nix-maid" ];
        };
}
