{
  personal =
    {
      pkgs,
      lib,
      homeConfig,
      ...
    }:
    let
      mkDconfSwitchScript' =
        input:
        lib.concatLines (
          lib.flatten (
            lib.mapAttrsToList (
              basepath: opts:
              lib.mapAttrsToList (
                key: value: "${lib.getExe pkgs.dconf} write /${basepath}/${key} \"'${value}'\""
              ) opts
            ) input
          )
        );
    in
    {
      home = {
        programs.niri.settings.cursor = {
          theme = "Adwaita";
          size = 24;
        };

        file.xdg_data = {
          "icons/Adwaita".source = "${pkgs.gnome-themes-extra}/share/icons/Adwaita";
          "icons/MoreWaita".source = "${pkgs.morewaita-icon-theme}/share/icons/MoreWaita";

          "themes/Adwaita".source = "${pkgs.gnome-themes-extra}/share/themes/Adwaita";
          "themes/Adwaita-dark".source = "${pkgs.gnome-themes-extra}/share/themes/Adwaita-dark";
        };

        file.xdg_config = {
          "gtk-3.0/settings.ini".text = ''
            [Settings]
            gtk-theme-name=Adwaita
            gtk-icon-theme-name=MoreWaita
            gtk-font-name=Inter 11
            gtk-cursor-theme-name=Adwaita
            gtk-cursor-theme-size=24
            gtk-enable-event-sounds=true
            gtk-enable-input-feedback-sounds=true
            gtk-decoration-layout=close,maximize,minimize:menu
          '';
          "gtk-4.0/settings.ini".text = ''
            [Settings]
            gtk-theme-name=Adwaita
            gtk-icon-theme-name=MoreWaita
            gtk-font-name=Inter 11
            gtk-cursor-theme-name=Adwaita
            gtk-cursor-theme-size=24
            gtk-enable-event-sounds=true
            gtk-enable-input-feedback-sounds=true
            gtk-decoration-layout=close,maximize,minimize:menu
          '';
        };

        services.darkman = {
          enable = true;
          lightModeScripts.gtk-theme = mkDconfSwitchScript' {
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-light";
              gtk-theme = "Adwaita";
            };
          };
          darkModeScripts.gtk-theme = mkDconfSwitchScript' {
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              gtk-theme = "Adwaita-dark";
            };
          };
        };
      };

    };
}
