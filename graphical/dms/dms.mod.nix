{
  niri,
  dms,
  quickshell,
  ...
}:
{
  graphical =
    {
      pkgs,
      lib,
      config,
      homeConfig,
      nixosConfig,
      ...
    }:
    let
      inherit (homeConfig.maid) systemdGraphicalTarget;
      inherit (nixosConfig.programs.nh) flake;
    in
    {
      nixpkgs.overlays = [
        (prev: final: {
          dms-shell = dms.packages.${pkgs.stdenv.buildPlatform.system}.default;
          quickshell = quickshell.packages.${pkgs.stdenv.buildPlatform.system}.default;
        })
      ];

      services.power-profiles-daemon.enable = lib.mkDefault true;
      services.accounts-daemon.enable = lib.mkDefault true;

      home.packages = [
        pkgs.dgop
        pkgs.matugen
        pkgs.cava
        pkgs.khal
        pkgs.dms-shell
        pkgs.dsearch
        pkgs.quickshell
      ];

      home.systemd.packages = [ pkgs.dsearch ];
      home.systemd.services = {
        dms = {
          description = "Dank Material Shell (DMS)";

          partOf = [ systemdGraphicalTarget ];
          requisite = [ systemdGraphicalTarget ];
          after = [ systemdGraphicalTarget ];

          restartIfChanged = true;

          environment.PATH = lib.mkForce null;

          serviceConfig = {
            Type = "dbus";
            BusName = "org.freedesktop.Notifications";
            ExecStart = "${pkgs.dms-shell}/bin/dms run --session";
            ExecReload = "${pkgs.procps}/bin/pkill -USR1 -x dms";
            Restart = "on-failure";
            RestartSec = 1.23;
            TimeoutStopSec = 10;
          };

          wantedBy = [ systemdGraphicalTarget ];
        };

        dsearch.wantedBy = [ config.home.maid.systemdTarget ];

        dms-link-flake-files = {
          description = "Link flake dms config";
          wantedBy = [ "default.target" ];
          script = ''
            ln -sf ${flake}/graphical/dms/settings.json ~/.config/DankMaterialShell/settings.json
            ln -sf ${flake}/graphical/dms/plugin_settings.json ~/.config/DankMaterialShell/plugin_settings.json
          '';
        };

        dms-create-niri-files = {
          description = "Create dms files for niri";
          wantedBy = [ "default.target" ];
          script = ''
            mkdir -p ~/.config/niri/dms
            touch ~/.config/niri/dms/{colors,layout,alttab,binds,wpblur,outputs}.kdl
          '';
        };
      };

      services.displayManager.dms-greeter = {
        enable = true;
        configHome = "/home/arakhor";
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

      home = {
        file.xdg_config =
          let
            gtkcss = # css
              ''
                @import url("dank-colors.css");
                GtkLabel.title {
                  opacity: 0;
                }
                window, decoration, decoration-overlay {
                  border-radius: 0;
                  box-shadow: unset;
                }
                window-frame, .window-frame:backdrop {
                  box-shadow: 0 0 0 black;
                  border-style: none;
                  margin: 0;
                  border-radius: 0;
                }
                .header-bar {
                  background-image: none;
                  background-color: #ededed;
                  box-shadow: none;
                }
                .titlebar {
                  border-radius: 0;
                }
                .window-frame.csd.popup {
                  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2), 0 0 0 1px rgba(0, 0, 0, 0.13);
                }
              '';

            qtconf = ver: ''
              [Appearance]
              icon_theme=MoreWaita
              custom_palette=true
              color_scheme_path=/home/arakhor/.config/qt${builtins.toString ver}ct/colors/matugen.conf
            '';
          in
          {
            "gtk-3.0/gtk.css".text = gtkcss;
            "gtk-4.0/gtk.css".text = gtkcss;
            "qt5ct/qt5ct.conf".text = qtconf 5;
            "qt6ct/qt6ct.conf".text = qtconf 6;
          };

        programs.niri = {
          settings.window-rules = [
            {
              matches = [ { app-id = "org.quickshell$"; } ];
              open-floating = true;
            }
          ];
          extraConfig = lib.concatLines (
            builtins.map (el: ''include "dms/${el}.kdl"'') [
              "alttab"
              "binds"
              "colors"
              "layout"
              "outputs"
              "wpblur"
            ]
          );
        };
      };

      preserveSystem.directories = [ "/var/lib/dms-greeter" ];
      preserveHome = {
        directories = [
          ".local/state/DankMaterialShell"
          ".config/niri/dms"
          ".cache/DankMaterialShell"
          ".cache/danksearch"
        ];
      };
    };
}
