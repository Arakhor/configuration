{
  graphical =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      qt5Support = true;

      qtPkgs = lib.optionals qt5Support [ pkgs.qt5 ] ++ [ pkgs.qt6 ];
      makeQtPath = prefix: (map (qt: "/etc/profiles/per-user/arakhor/${qt.qtbase.${prefix}}") qtPkgs);

      envVars = {
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "qt6ct";
        QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
      };

      envVarsExtra = {
        QT_PLUGIN_PATH = makeQtPath "qtPluginPrefix";
        QML2_IMPORT_PATH = makeQtPath "qtQmlPrefix";
      };
    in
    {
      programs.nushell.environmentVariables =
        envVars
        // envVarsExtra
        // {
          ENV_CONVERSIONS = with config.lib.nushell; {
            QT_PLUGIN_PATH = esepListConverter;
            QML2_IMPORT_PATH = esepListConverter;
          };
        };

      home = {
        packages =
          lib.optionals qt5Support [
            pkgs.libsForQt5.qt5ct
            pkgs.libsForQt5.qtdeclarative
            pkgs.libsForQt5.qtmultimedia
          ]
          ++ [
            pkgs.kdePackages.qt6ct
            pkgs.kdePackages.qtdeclarative
            pkgs.kdePackages.qtmultimedia
          ];

        systemd.globalEnvironment =
          envVars // (builtins.mapAttrs (_: lib.concatStringsSep ":") envVarsExtra);
      };
    };
}
