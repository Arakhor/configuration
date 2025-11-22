{
  universal =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      fzfArgs = [
        # Search mode
        "--exact"
        # Search result
        "--no-sort"
        # Interface
        "--bind=ctrl-z:ignore,btab:up,tab:down"
        "--cycle"
        "--keep-right"
        "--color=16"
        # Layout
        "--layout=reverse"
        "--height=100%"
        "--border=none"
        "--scrollbar=▌"
        "--info=inline"
        # Display
        "--tabstop=1"
        # Scripting
        "--exit-0"
        # Preview
        "--preview='nucat {}'"
        "--preview-window=right,50%,rounded"
      ];

      ezaArgs = [
        "--icons=always"
        "--color=always"
        "--no-user"
        "--no-permissions"
        "--no-filesize"
        "--no-time"
        "--group-directories-first"
      ];
    in
    {
      packages = with pkgs; [
        fzf
        eza
        bat
        fd
        ripgrep

        (config.lib.nushell.writeNuBin "nucat" # nu
          ''
            def main [path] {
                let type = (ls -D $path | get type).0
                match $type {
                    dir => { ${pkgs.eza}/bin/eza ${lib.concatStringsSep " " ezaArgs} -TL3 $"($path)" }
                    file => {
                      let extension = ($path | path parse | get extension)
                      match $extension {
                          "nu"|"nuon" => { open --raw $"($path)" | nu-highlight }
                          _ => { ${pkgs.bat}/bin/bat -Ppf $"($path)" }
                      }
                     }
                    _ => { }
                }
            }
          ''
        )
      ];

      programs.nushell.interactiveShellInit = # nu
        ''
          $env.FZF_DEFAULT_COMMAND = "${lib.getExe pkgs.fd} --type f"
          $env.FZF_DEFAULT_OPTS = "${lib.concatStringsSep " " fzfArgs}"
          $env._ZO_FZF_OPTS = $env.FZF_DEFAULT_OPTS
          $env.YAZI_ZOXIDE_OPTS = $env.FZF_DEFAULT_OPTS

          $env.BAT_THEME = "base16"
        '';
    };
}
