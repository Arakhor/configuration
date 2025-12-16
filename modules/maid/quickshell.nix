{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.quickshell;
in
{
  options.programs.quickshell = {
    enable = lib.mkEnableOption "quickshell, a flexbile QtQuick-based desktop shell toolkit.";
    package = lib.mkPackageOption pkgs "quickshell" { nullable = true; };
    configs = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        A set of configs to include in the quickshell config directory. The key is the name of the config.

        The configuration that quickshell should use can be specified with the `activeConfig` option.
      '';
    };
    activeConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        The name of the config to use.

        If `null`, quickshell will attempt to use a config located in `$XDG_CONFIG_HOME/quickshell` instead of one of the named sub-directories.
      '';
    };

    systemd = {
      enable = lib.mkEnableOption "quickshell systemd service";
      target = lib.mkOption {
        type = lib.types.str;
        default = config.maid.systemdGraphicalTarget;
        defaultText = lib.literalExpression "config.maid.systemdGraphicalTarget";
        example = "hyprland-session.target";
        description = ''
          The systemd target that will automatically start quickshell.

          If you set this to a WM-specific target, make sure that systemd integration for that WM is enabled (e.g. `wayland.windowManager.hyprland.systemd.enable`). **This is typically true by default**.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (cfg.configs != { }) {
        file.xdg_config = lib.mapAttrs' (name: path: {
          name = "quickshell/${name}";
          value.source = path;
        }) cfg.configs;
      })
      {
        packages = [ cfg.package ];
      }
      (lib.mkIf cfg.systemd.enable {
        systemd.services.quickshell = {
          description = "quickshell";
          documentation = "https://quickshell.outfoxxed.me/docs/";
          after = [ cfg.systemd.target ];

          serviceConfig = {
            ExecStart =
              lib.getExe cfg.package + (if cfg.activeConfig == null then "" else " --config ${cfg.activeConfig}");
            Restart = "on-failure";
          };

          wantedBy = [ cfg.systemd.target ];
        };
      })
    ]
  );
}
