{
    graphical =
        {
            lib,
            pkgs,
            config,
            ...
        }:
        let
            cfg = config.style;

            qt5Support = true;

            qtPkgs = lib.optionals qt5Support [ pkgs.qt5 ] ++ [ pkgs.qt6 ];
            makeQtPath = prefix: (map (qt: "/etc/profiles/per-user/arakhor/${qt.qtbase.${prefix}}") qtPkgs);

            envVars = {
                QT_QPA_PLATFORM = "wayland";
                QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
                QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
                QT_AUTO_SCREEN_SCALE_FACTOR = "1";
            };

            envVarsExtra = {
                QT_PLUGIN_PATH = makeQtPath "qtPluginPrefix";
                QML2_IMPORT_PATH = makeQtPath "qtQmlPrefix";
            };

            qtConf =
                ver:
                lib.generators.toINI { } {
                    Appearance = {
                        icon_theme = cfg.icons.name;
                        custom_palette = true;
                        color_scheme_path = "/home/arakhor/.config/qt${toString ver}ct/colors/noctalia.conf";
                    };
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
                        pkgs.libsForQt5.qt5ct
                        pkgs.libsForQt5.qtdeclarative
                        pkgs.libsForQt5.qtmultimedia
                        pkgs.libsForQt5.kirigami2
                        pkgs.libsForQt5.sonnet
                    ]
                    ++ [
                        pkgs.kdePackages.qt6ct
                        pkgs.kdePackages.qtdeclarative
                        pkgs.kdePackages.qtmultimedia
                        pkgs.kdePackages.kirigami.unwrapped
                        pkgs.kdePackages.sonnet
                    ]
                    ++ [
                        pkgs.ffmpeg # for qtmultimedia
                    ];

                file.xdg_config = {
                    "qt5ct/qt5ct.conf".text = qtConf 5;
                    "qt6ct/qt6ct.conf".text = qtConf 6;
                };

            };

            environment.sessionVariables =
                envVars // (builtins.mapAttrs (_: lib.concatStringsSep ":") envVarsExtra);
        };
}
