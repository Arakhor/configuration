{
    graphical =
        {
            pkgs,
            lib,
            config,
            ...
        }:
        let
            cfg = config.style;

            gtkTheme = {
                name = "adw-gtk3";
                package = pkgs.adw-gtk3;
            };

            buttonLayout.normal = "close,maximize,minimize:menu";
            buttonLayout.wm = "appmenu:close";

            # GTK Settings
            gtkSettings = with cfg; {
                gtk-cursor-theme-name = cursor.name;
                gtk-cursor-theme-size = cursor.size;
                gtk-icon-theme-name = icons.name;
                gtk-theme-name = gtkTheme.name;
                gtk-font-name = "${cfg.fonts.sansSerif.name} 10";

                # gtk-menu-images = "true";
                # gtk-modules = "colorreload-gtk-module:appmenu-gtk-module";
                gtk-primary-button-warps-slider = "false";
                gtk-shell-shows-menubar = 1;

                gtk-decoration-layout = buttonLayout.wm;
                gtk-enable-event-sounds = true;
                gtk-enable-input-feedback-sounds = true;
            };

            gtkIni = lib.generators.toINI { } { Settings = gtkSettings; };
        in
        {
            environment.systemPackages = [
                gtkTheme.package
            ];

            maid-users.file.xdg_config = {
                "gtk-3.0/settings.ini".text = gtkIni;
                "gtk-4.0/settings.ini".text = gtkIni;
            };

            maid-users.dconf.settings = with cfg; {
                "/org/gnome/desktop/interface/color-scheme" = "prefer-dark";
                "/org/gnome/desktop/interface/cursor-size" = cursor.size;
                "/org/gnome/desktop/interface/cursor-theme" = cursor.name;
                "/org/gnome/desktop/interface/gtk-theme" = gtkTheme.name;
                "/org/gnome/desktop/interface/icon-theme" = icons.name;
                "/org/gnome/desktop/wm/preferences/button-layout" = buttonLayout.wm;
            };

            style.dynamic.templates =
                let
                    keys = config.lib.style.genMatugenKeys { };
                    template =
                        with keys;
                        # css
                        ''
                            @define-color accent_color ${primary};
                            @define-color accent_bg_color ${primary};
                            @define-color accent_fg_color ${on_primary};
                            @define-color window_bg_color ${surface};
                            @define-color window_fg_color ${on_surface};
                            @define-color headerbar_bg_color ${surface};
                            @define-color headerbar_fg_color ${on_surface};
                            @define-color popover_bg_color ${surface_container_high};
                            @define-color popover_fg_color ${on_surface};
                            @define-color view_bg_color ${surface};
                            @define-color view_fg_color ${on_surface};
                            @define-color card_bg_color ${surface};
                            @define-color card_fg_color ${on_surface};

                            @define-color sidebar_bg_color ${surface_container};
                            @define-color sidebar_fg_color ${on_surface};
                            @define-color sidebar_border_color @window_bg_color;
                            @define-color sidebar_backdrop_color @window_bg_color;
                        '';
                in
                {
                    gtk-3 = {
                        text = template;
                        target = ".config/gtk-3.0/gtk.css";
                    };
                    gtk-4 = {
                        text = template;
                        target = ".config/gtk-4.0/gtk.css";
                    };
                };
        };
}
