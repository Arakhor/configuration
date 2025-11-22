{
  graphical =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages = with pkgs; [
        adw-gtk3
        adwaita-icon-theme
        morewaita-icon-theme
      ];

      home = {
        gsettings.settings.org.gnome.desktop.interface = {
          "gtk-theme" = "adw-gtk3";
          "color-scheme" = "prefer-dark";
          "icon-theme" = "MoreWaita";
        };

        programs.niri.settings.cursor = {
          theme = "Adwaita";
          size = 24;
        };
      };
    };
}
