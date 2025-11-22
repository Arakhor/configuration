inputs:
# treefmt.nix
{ pkgs, lib, ... }:
let
  topiary-nushell = inputs.topiary-nushell;
  tree-sitter-nu = inputs.nushell-nightly.packages.${pkgs.stdenv.hostPlatform.system}.tree-sitter-nu;

  topiary-nu = inputs.wrapper-manager.lib.wrapWith pkgs {
    basePackage = pkgs.topiary;
    prependFlags = [ "--merge-configuration" ];
    env = {
      TOPIARY_CONFIG_FILE.value =
        pkgs.writeText "languages.ncl"
          # nickel
          ''
            {
              languages = {
                nu = {
                  indent = "    ", # 4 spaces
                  extensions = ["nu"],
                  grammar.source.path = "${tree-sitter-nu}/parser"
                },
              },
            }
          '';
      TOPIARY_LANGUAGE_DIR.value = "${topiary-nushell}/languages";
    };
  };

in
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
      command = lib.getExe topiary-nu;
      options = [ "format" ];
      includes = [ "*.nu" ];
    };
  };
}
