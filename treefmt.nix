inputs:
# treefmt.nix
{ pkgs, lib, ... }:
{
    # Used to find the project root
    projectRootFile = "flake.nix";

    programs.nixfmt = {
        enable = true;
        indent = 4;
    };

    programs.keep-sorted.enable = true;

    settings.formatter = {
        topiary-nushell = {
            command = lib.getExe inputs.topiary-nushell.packages.${pkgs.stdenv.hostPlatform.system}.default;
            options = [ "format" ];
            includes = [ "*.nu" ];
        };
    };
}
