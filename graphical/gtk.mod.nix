{
  graphical =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      gtkTheme = "adw-gtk3";
      iconTheme = "Papirus-Dark";
      cursorTheme = "Adwaita";
      cursorSize = 24;

      # GTK Settings
      gtkSettings = {
        "gtk-application-prefer-dark-theme" = 1;
        "gtk-cursor-theme-name" = cursorTheme;
        "gtk-cursor-theme-size" = cursorSize;
        "gtk-icon-theme-name" = iconTheme;
        "gtk-theme-name" = gtkTheme;
        "gtk-font-name" = "${config.fonts.sans} 10";
        "gtk-decoration-layout" = "close,maximize,minimize:menu";
        "gtk-enable-event-sounds" = true;
        "gtk-enable-input-feedback-sounds" = true;
      };

      gtkIni = lib.generators.toINI { } { Settings = gtkSettings; };
    in
    {
      home = {
        packages = with pkgs; [
          adw-gtk3
          papirus-icon-theme
        ];

        file.xdg_config = {
          "gtk-3.0/settings.ini".text = gtkIni;
          "gtk-4.0/settings.ini".text = gtkIni;
        };

        dconf.settings = {
          "/org/gnome/desktop/interface/cursor-size" = cursorSize;
          "/org/gnome/desktop/interface/cursor-theme" = cursorTheme;
          "/org/gnome/desktop/interface/gtk-theme" = gtkTheme;
          "/org/gnome/desktop/interface/icon-theme" = iconTheme;
        };

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
    };
}
