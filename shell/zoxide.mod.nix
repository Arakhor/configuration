{
  universal =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.zoxide ];

      programs.nushell.interactiveShellInit = # nu
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

          alias g = __zoxide_z
          alias gi = __zoxide_zi

          $env.config.hooks.env_change.PWD = (
              $env.config.hooks.env_change.PWD?
              | default []
              | append {|_, dir| zoxide add -- $dir }
          )
        '';

      preserveHome.directories = [ ".local/share/zoxide" ];
    };
}
