{
    universal =
        { pkgs, lib, ... }:
        {
            programs.direnv = {
                enable = true;
                silent = true;
            };

            programs.nushell.settings.hooks.env_change.PWD = [
                (lib.mkNushellInline # nu
                    ''
                        {||
                            direnv export json
                            | from json
                            | default {}
                            | load-env
                            $env.ENV_CONVERSIONS = $env.ENV_CONVERSIONS
                        }
                    ''
                )
            ];

            environment.systemPackages = with pkgs; [
                nil
                nixd
                npins
                nixfmt
                gitMinimal
                statix
                deadnix
            ];

            preserveHome.directories = [ ".local/share/direnv" ];
        };
}
