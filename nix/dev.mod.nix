{
    universal =
        { pkgs, ... }:
        {
            wrappers.nixfmt = {
                basePackage = pkgs.nixfmt-rfc-style;
                prependFlags = [
                    "-v"
                    "-q"
                    "--indent=4"
                    "-s"
                ];
            };
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
                wrapped.nixfmt
                gitMinimal
                statix
                deadnix
            ];
        };
}
