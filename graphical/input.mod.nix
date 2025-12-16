{ xremap, ... }:
{
  graphical =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let

      cfg = config.home.services.xremap;
      localLib = xremap.localLib { inherit pkgs lib cfg; };
      inherit (localLib) mkExecStart configFile;
      inherit (lib) mkIf mkMerge optionalAttrs;
    in
    {
      imports = [
        {
          home = {
            options.services.xremap = localLib.commonOptions;
            config.systemd.services.xremap = mkIf cfg.enable {
              description = "xremap user service";
              path = [ cfg.package ];
              # NOTE: xremap needs DISPLAY:, WAYLAND_DISPLAY: and a bunch of other stuff in the environment to launch graphical applications (launch:)
              # On Gnome after gnome-session.target is up - those variables are populated
              after = lib.mkIf cfg.withGnome [ "gnome-session.target" ];
              wantedBy = [ "graphical-session.target" ];
              serviceConfig = mkMerge [
                {
                  KeyringMode = "private";
                  SystemCallArchitectures = [ "native" ];
                  RestrictRealtime = true;
                  ProtectSystem = true;
                  SystemCallFilter = map (x: "~@${x}") [
                    "clock"
                    "debug"
                    "module"
                    "reboot"
                    "swap"
                    "cpu-emulation"
                    "obsolete"
                    # NOTE: These two make the spawned processes drop cores
                    # "privileged"
                    # "resources"
                  ];
                  LockPersonality = true;
                  UMask = "077";
                  RestrictAddressFamilies = "AF_UNIX";
                  ExecStart = mkExecStart configFile;
                }
                (optionalAttrs cfg.debug { Environment = [ "RUST_LOG=debug" ]; })
              ];
            };
          };
        }
      ];

      # nixpkgs.overlays = [
      #   xremap.overlays.default
      # ];

      hardware.uinput.enable = true;

      users.users.arakhor.extraGroups = [
        "input"
        "uinput"
      ];

      home.programs.niri.settings.input = {
        focus-follows-mouse.enable = true;
        warp-mouse-to-focus.enable = true;
        warp-mouse-to-focus.mode = "center-xy-always";

        keyboard.xkb.layout = config.locale.keyboard-layout;
        touchpad = {
          dwt = true;
          tap = true;
          natural-scroll = false;
          click-method = "clickfinger";
          # accel-profile = "flat";
          # accel-speed = 0.0;
        };
      };

      home.services.xremap = {
        enable = true;
        withNiri = true;
        config.modmap = [
          {
            name = "global";
            remap = {
              capslock = {
                held = "control_l";
                alone = "esc";
                free_hold = true;
              };
              space = {
                held = "shift_l";
                alone = "space";
                free_hold = false;
                alone_timeout_millis = 300;
              };
              control_l = "capslock";
            };
          }
        ];
      };
    };
}
