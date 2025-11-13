{ nix-index-database, ... }:
{
    universal = {
        imports = [ nix-index-database.nixosModules.nix-index ];

        programs.nix-index-database.comma.enable = true;

        programs.nushell.interactiveShellInit = # nu
            ''
                $env.config.hooks.command_not_found = {|command|
                    try { , $command }
                }
            '';
    };
}
