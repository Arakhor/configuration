{
  graphical =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      # GTK Settings
      gtkSettings = {
        "gtk-application-prefer-dark-theme" = 1;
        "gtk-cursor-theme-name" = "Adwaita";
        "gtk-cursor-theme-size" = 24;
        "gtk-font-name" = "${config.fonts.sans} 10";
        "gtk-icon-theme-name" = "MoreWaita";
        "gtk-theme-name" = "adw-gtk3";
      };

      gtkIni = lib.generators.toINI { } { Settings = gtkSettings; };
    in
    {
      home = {
        packages = with pkgs; [
          adw-gtk3
          adwaita-icon-theme
          morewaita-icon-theme
        ];

        file.xdg_config = {
          "gtk-3.0/settings.ini".text = gtkIni;
          "gtk-4.0/settings.ini".text = gtkIni;
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
