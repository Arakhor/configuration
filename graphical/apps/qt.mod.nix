{
    graphical =
        {
            lib,
            pkgs,
            config,
            ...
        }:
        let
            qt5Support = false;

            qtPkgs = lib.optionals qt5Support [ pkgs.qt5 ] ++ [ pkgs.qt6 ];
            makeQtPath = prefix: (map (qt: "/etc/profiles/per-user/arakhor/${qt.qtbase.${prefix}}") qtPkgs);

            envVars = {
                QT_QPA_PLATFORM = "wayland";
                QT_QPA_PLATFORMTHEME = "gnome";
                QT_WAYLAND_DECORATION = "adwaita";
                QT_AUTO_SCREEN_SCALE_FACTOR = "1";
            };

            envVarsExtra = {
                QT_PLUGIN_PATH = makeQtPath "qtPluginPrefix";
                QML2_IMPORT_PATH = makeQtPath "qtQmlPrefix";
            };

        in
        {
            programs.nushell.environmentVariables = lib.mkMerge [
                # envVars
                # envVarsExtra
                {
                    ENV_CONVERSIONS = with config.lib.nushell; {
                        QT_PLUGIN_PATH = esepListConverter;
                        QML2_IMPORT_PATH = esepListConverter;
                        QTWEBKIT_PLUGIN_PATH = esepListConverter;
                    };
                }
            ];

            maid-users = {
                packages =
                    lib.optionals qt5Support [
                        pkgs.adwaita-qt
                        pkgs.qadwaitadecorations
                        pkgs.qgnomeplatform
                    ]
                    ++ [
                        pkgs.adwaita-qt6
                        pkgs.qadwaitadecorations-qt6
                        pkgs.qgnomeplatform-qt6
                    ];
            };

            environment.sessionVariables =
                envVars // (builtins.mapAttrs (_: lib.concatStringsSep ":") envVarsExtra);
        };
}
