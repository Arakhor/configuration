inputs:
# treefmt.nix
{ pkgs, lib, ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";

  programs.nixfmt = {
    enable = true;
    indent = 2;
    strict = true;
  };

  programs.keep-sorted.enable = true;

  settings.formatter = {
    "topiary-nushell" = {
      command = lib.getExe inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.topiary-nu;
      options = [ "format" ];
      includes = [ "*.nu" ];
    };
  };
}
