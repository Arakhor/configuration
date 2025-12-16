{
  graphical.home =
    { pkgs, config, ... }:
    let
      mkGtkCss =
        version:
        pkgs.writeText "gtk-${toString version}.css" (
          config.gtk."gtk${toString version}".extraCss
          + /* css */ ''
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
          ''
        );

    in
    {
      packages = with pkgs; [
        adw-gtk3
        adwaita-icon-theme
        morewaita-icon-theme
      ];

      gsettings.settings.org.gnome.desktop = {
        wm.preferences = {
          "button-layout" = ":appmenu";
        };
        sound = {
          "event-sounds" = true;
          "input-feedback-sounds" = true;
        };
        interface = {
          "gtk-theme" = "adw-gtk3";
          "color-scheme" = "prefer-dark";
          "icon-theme" = "MoreWaita";
        };

      };

      programs.niri.settings.cursor = {
        theme = "Adwaita";
        size = 24;
      };
    };
}
