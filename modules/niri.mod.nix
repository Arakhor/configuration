{ niri, ... }:
{
  universal.home =
    {
      pkgs,
      lib,
      config,
      nixosConfig,
      ...
    }:
    let
      cfg = config.programs.niri;
    in
    {
      imports = [
        niri.lib.internal.settings-module
        {
          config.programs.niri = {
            enable = lib.mkForce nixosConfig.programs.niri.enable;
            package = lib.mkForce nixosConfig.programs.niri.package;
          };
        }
      ];

      options.programs.niri = {
        enable = lib.mkEnableOption "niri";
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.niri-stable;
          description = "The niri package to use.";
        };
        extraConfig = lib.mkOption {
          type = lib.types.lines;
          description = "Extra lines to add after config validation.";
          default = "";
        };
      };

      config = lib.mkIf cfg.enable {

        lib.niri.actions = lib.mergeAttrsList (
          map (name: { ${name} = niri.lib.kdl.magic-leaf name; }) (import "${niri}/memo-binds.nix")
        );

        packages = [ cfg.package ];
        file.xdg_config."niri/config.kdl".text = lib.concatLines [
          (builtins.readFile (niri.lib.internal.validated-config-for pkgs cfg.package cfg.finalConfig))
          cfg.extraConfig
        ];
      };
    };
}
