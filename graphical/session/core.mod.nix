{
    graphical =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        {
            lib.session = rec {
                sliceSuffix = lib.optionalString (config.programs.uwsm.enable or false) "-graphical";
                sessionSlice = "session${sliceSuffix}.slice";
                backgroundSlice = "background${sliceSuffix}.slice";
                appSlice = "app${sliceSuffix}.slice";
                defaultTarget = "default.target";
                graphicalTarget = "graphical-session.target";
            };

            services.xserver.excludePackages = [ pkgs.xterm ];

            # Some apps like vscode need the keyring for saving credentials.
            # WARN: May need to manually create a "login" keyring for this to work
            # correctly. Seahorse is an easy way to do this. To enable automatic
            # keyring unlock on login use the same password as our user.
            services.gnome.gnome-keyring.enable = true;
            preserveHome.directories = lib.singleton {
                directory = ".local/share/keyrings";
                mode = "0700";
            };
            programs.seahorse.enable = true;

            # Fix the session slice for user services.
            systemd.user.units =
                lib.genAttrs
                    [
                        "at-spi-dbus-bus.service"
                        "xdg-desktop-portal-gtk.service"
                        "xdg-desktop-portal-gnome.service"
                        "xdg-desktop-portal.service"
                        "xdg-document-portal.service"
                        "xdg-permission-store.service"
                    ]
                    (_: {
                        overrideStrategy = "asDropin";
                        text = ''
                            [Service]
                            Slice=${config.lib.session.sessionSlice}
                        '';
                    });
        };
}
