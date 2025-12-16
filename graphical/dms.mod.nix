{ niri, ... }:
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
      programs.dms-shell = {
        enable = true;
      };

      programs.dsearch = {
        enable = true;
        systemd.enable = true;
      };

      services.displayManager.dms-greeter = {
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

      preserveSystem.directories = [ "/var/lib/dms-greeter" ];

      preserveHome = {
        files = [
          ".config/gtk-3.0/dank-colors.css"
          ".config/gtk-4.0/dank-colors.css"

          ".config/ghostty/config-dankcolors"
        ];
        directories = [
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

        # systemd.services.dms = {
        #   description = "Dank Material Shell (DMS)";

        #   partOf = [ systemdGraphicalTarget ];
        #   requisite = [ systemdGraphicalTarget ];
        #   after = [ systemdGraphicalTarget ];

        #   environment.PATH = lib.mkForce null;

        #   serviceConfig = {
        #     Type = "simple";
        #     ExecStart = "${pkgs.dms-shell}/bin/dms run --session";
        #     ExecReload = "${pkgs.procps}/bin/pkill -USR1 -x dms";
        #     Restart = "always";
        #     RestartSec = 2;
        #     TimeoutStopSec = 10;
        #   };

        #   wantedBy = [ systemdGraphicalTarget ];
        # };

        programs.niri = {
          extraConfig = lib.concatLines (
            builtins.map (el: ''include "dms/${el}.kdl"'') [
              "alttab"
              "binds"
              "colors"
              "layout"
              "wpblur"
            ]
          );
        };
      };
    };
}
