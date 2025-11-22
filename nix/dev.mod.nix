{
  universal =
    { pkgs, ... }:
    {
      programs.direnv = {
        enable = true;
        silent = true;
      };
      programs.nushell.interactiveShellInit = # nu
        ''
          use enverlay
          enverlay auto
        '';
      home.packages = with pkgs; [
        nil
        nixd
        npins
        nixfmt-rfc-style
        gitMinimal
        statix
        deadnix
      ];
      preserveHome.directories = [ ".local/share/direnv" ];
    };
}
