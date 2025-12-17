{
  universal =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.zoxide ];

      programs.nushell = {
        interactiveShellInit = # nu
          ''
            # Jump to a directory using only keywords.
            def --env --wrapped __zoxide_z [...rest: string] {
                let path = match $rest {
                    [] => { '~' }
                    ['-'] => { '-' }
                    [$arg] if ($arg | path expand | path type) == 'dir' => { $arg }
                    _ => {
                        zoxide query --exclude $env.PWD -- ...$rest | str trim -r -c "\n"
                    }
                }
                cd $path
            }

            # Jump to a directory using interactive search.
            def --env --wrapped __zoxide_zi [...rest: string] {
                cd $'(zoxide query --interactive -- ...$rest | str trim -r -c "\n")'
            }
          '';

        shellAliases = {
          z = "__zoxide_z";
          zi = "__zoxide_zi";
        };

        settings.hooks.env_change.PWD = [
          (lib.ns.nushell.mkNushellInline "{|_, dir| zoxide add -- $dir }")
        ];
      };

      preserveHome.directories = [ ".local/share/zoxide" ];
    };
}
