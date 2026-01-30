{ nix-index-database, ... }:
{
    universal = {
        imports = [ nix-index-database.nixosModules.nix-index ];

        programs.nix-index-database.comma.enable = true;

    };
}
