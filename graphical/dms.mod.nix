{
  niri,
  dgop,
  dms,
  quickshell,
  danksearch,
  matugen,
  ...
}:
{
  graphical =
    {
      pkgs,
      lib,
      homeConfig,
      nixosConfig,
      ...
    }:
    let
      inherit (homeConfig.maid) systemdGraphicalTarget;
    in
    {
      nixpkgs.overlays = [
        (
          final: prev:
          let
            inherit (prev.stdenv.hostPlatform) system;
          in
          {
            quickshell = quickshell.packages.${system}.default;
            dmsCli = dms.packages.${system}.dmsCli;
            dgop = dgop.packages.${system}.dgop;
            dsearch = danksearch.packages.${system}.dsearch;
            dankMaterialShell = dms.packages.${system}.dankMaterialShell;
            matugen = matugen.packages.${system}.default;
          }
        )
      ];

      imports = [
        dms.nixosModules.greeter
      ];

      programs.dankMaterialShell.greeter = {
        enable = true;
        configHome = "/persist/home/arakhor";
        logs.save = true;
        compositor =
          let
            niri-cfg-modules = lib.evalModules {
              modules = [
                niri.lib.internal.settings-module
                (
                  let
                    cfg = homeConfig.programs.niri.settings;
                  in
                  {
                    programs.niri.settings = {
                      hotkey-overlay.skip-at-startup = true;

                      input = cfg.input;
                      # causes a deprecation warning otherwise
                      cursor = builtins.removeAttrs cfg.cursor [ "hide-on-key-press" ];
                      outputs = cfg.outputs;
                      gestures.hot-corners.enable = false;

                      layout = cfg.layout // {
                        background-color = "#000000";
                      };

                      debug.keep-max-bpc-unchanged = true;
                    };
                  }
                )
              ];
            };

            niri-config =
              niri.lib.internal.validated-config-for pkgs nixosConfig.programs.niri.package
                niri-cfg-modules.config.programs.niri.finalConfig;

          in
          {
            name = "niri";
            customConfig = builtins.readFile niri-config;
          };
      };

      services.accounts-daemon.enable = true;

      packages = [
        # Core
        pkgs.quickshell
        pkgs.dankMaterialShell
        pkgs.dmsCli

        pkgs.ddcutil

        # System Monitoring
        pkgs.dgop

        # Clipboard
        pkgs.cliphist
        pkgs.wl-clipboard

        # Networking
        pkgs.glib
        # pkgs.networkmanager

        # Brightness
        pkgs.brightnessctl

        # Color Picker
        pkgs.hyprpicker

        # Dynamic Theming
        pkgs.matugen

        # Audio Visualiser
        pkgs.cava

        # Calendar Events
        pkgs.khal

        # System Sounds
        pkgs.ffmpeg

        # Search
        pkgs.dsearch
      ];

      preserveHome = {
        files = [
          ".config/qt5ct/colors/matugen.conf"
          ".config/qt6ct/colors/matugen.conf"

          ".config/gtk-3.0/dank-colors.css"
          ".config/gtk-4.0/dank-colors.css"

          ".config/ghostty/config-dankcolors"
        ];
        directories = [
          ".local/share/color-schemes"
          ".local/state/DankMaterialShell"
          ".config/DankMaterialShell"
          ".config/niri/dms"
          ".cache/DankMaterialShell"
          ".cache/danksearch"
        ];
      };

      home = {
        file.xdg_config =
          let
            qt = ''
              [Appearance]
              custom_palette=true
              color_scheme_path=/home/arakhor/.local/share/color-schemes/DankMatugen.colors
            '';
            gtk = ''
              @import url("dank-colors.css");
            '';
          in
          {
            "gtk-3.0/gtk.css".source = "{{xdg_config_home}}/gtk-3.0/dank-colors.css";
            "gtk-4.0/gtk.css".text = gtk;
            "qt5ct/qt5ct.conf".text = qt;
            "qt6ct/qt6ct.conf".text = qt;
          };

        systemd.services.cliphist = {
          description = "Clipboard management daemon";
          partOf = [ systemdGraphicalTarget ];
          after = [ systemdGraphicalTarget ];
          script = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --watch ${lib.getExe pkgs.cliphist} store";
          wantedBy = [ systemdGraphicalTarget ];
        };

        systemd.services.cliphist-images = {
          description = "Clipboard management daemon - images";
          partOf = [ systemdGraphicalTarget ];
          after = [ systemdGraphicalTarget ];
          script = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --type image --watch ${lib.getExe pkgs.cliphist} store";
          wantedBy = [ systemdGraphicalTarget ];
        };

        systemd.services.dsearch = {
          description = "dsearch - Fast filesystem search service";
          after = [ "network.target" ];
          script = "${lib.getExe pkgs.dsearch} serve";
          serviceConfig = {
            StandardOutput = "journal";
            StandardError = "journal";
            SyslogIdentifier = "dsearch";
          };
          wantedBy = [ "default.target" ];
        };

        systemd.services.dms = {
          description = "Dank Material Shell (DMS)";

          partOf = [ systemdGraphicalTarget ];
          requisite = [ systemdGraphicalTarget ];
          after = [ systemdGraphicalTarget ];

          environment.PATH = lib.mkForce null;

          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.dmsCli}/bin/dms run --session";
            ExecReload = "${pkgs.procps}/bin/pkill -USR1 -x dms";
            Restart = "always";
            RestartSec = 2;
            TimeoutStopSec = 10;
          };

          wantedBy = [ systemdGraphicalTarget ];
        };

        programs.niri = {
          extraConfig = ''
            include "dms/colors.kdl"
          '';

          settings = {
            binds =
              with homeConfig.lib.niri.actions;
              let
                dms-ipc = spawn "dms" "ipc";
              in
              {
                "Mod+Space" = {
                  action = dms-ipc "spotlight" "toggle";
                  hotkey-overlay.title = "Toggle Application Launcher";
                };
                "Mod+N" = {
                  action = dms-ipc "notifications" "toggle";
                  hotkey-overlay.title = "Toggle Notification Center";
                };
                "Mod+S" = {
                  action = dms-ipc "settings" "toggle";
                  hotkey-overlay.title = "Toggle Settings";
                };
                "Mod+P" = {
                  action = dms-ipc "notepad" "toggle";
                  hotkey-overlay.title = "Toggle Notepad";
                };
                "Super+Alt+L" = {
                  action = dms-ipc "lock" "lock";
                  hotkey-overlay.title = "Toggle Lock Screen";
                };
                "Mod+X" = {
                  action = dms-ipc "powermenu" "toggle";
                  hotkey-overlay.title = "Toggle Power Menu";
                };
                "XF86AudioRaiseVolume" = {
                  allow-when-locked = true;
                  action = dms-ipc "audio" "increment" "3";
                };
                "XF86AudioLowerVolume" = {
                  allow-when-locked = true;
                  action = dms-ipc "audio" "decrement" "3";
                };
                "XF86AudioMute" = {
                  allow-when-locked = true;
                  action = dms-ipc "audio" "mute";
                };
                "XF86AudioMicMute" = {
                  allow-when-locked = true;
                  action = dms-ipc "audio" "micmute";
                };
                "Mod+Alt+N" = {
                  allow-when-locked = true;
                  action = dms-ipc "night" "toggle";
                  hotkey-overlay.title = "Toggle Night Mode";
                };
                "Mod+M" = {
                  action = dms-ipc "processlist" "toggle";
                  hotkey-overlay.title = "Toggle Process List";
                };
                "Mod+V" = {
                  action = dms-ipc "clipboard" "toggle";
                  hotkey-overlay.title = "Toggle Clipboard Manager";
                };
                "XF86MonBrightnessUp" = {
                  allow-when-locked = true;
                  action = dms-ipc "brightness" "increment" "5" "";
                };
                "XF86MonBrightnessDown" = {
                  allow-when-locked = true;
                  action = dms-ipc "brightness" "decrement" "5" "";
                };
              };
          };
        };
      };

    };
}
