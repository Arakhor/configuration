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
            settings = {
                cornerRadius = 12;
                borderWidth = 2;
                gapSize = 16;
                opacity = 1.0;

                cursor = {
                    name = "Bibata-Modern-Classic";
                    size = 24;
                    package = pkgs.bibata-cursors;
                };

                icons = {
                    name = "Papirus-Dark";
                    package = pkgs.papirus-icon-theme;
                };
            };
        in
        {
            options.style = {
                cornerRadius = lib.mkOption {
                    type = lib.types.int;
                    description = "Corner radius to use for all styled applications";
                    default = settings.cornerRadius;
                };

                borderWidth = lib.mkOption {
                    type = lib.types.int;
                    description = "Border width in pixels for all styled applications";
                    default = settings.borderWidth;
                };

                gapSize = lib.mkOption {
                    type = lib.types.int;
                    description = "Gap size in pixels for all styled applications";
                    default = settings.gapSize;
                };

                opacity = lib.mkOption {
                    description = "Background opacity for all styled applications";
                    type = lib.types.float;
                    default = settings.opacity;
                };

                cursor = {
                    name = lib.mkOption {
                        description = "The cursor name within the package.";
                        type = lib.types.nullOr lib.types.str;
                        default = settings.cursor.name;
                    };
                    size = lib.mkOption {
                        description = "The cursor size.";
                        type = lib.types.nullOr lib.types.int;
                        default = settings.cursor.size;
                    };
                    package = lib.mkOption {
                        description = "Package providing the cursor theme.";
                        type = lib.types.nullOr lib.types.package;
                        default = settings.cursor.package;
                    };
                };

                icons = {
                    name = lib.mkOption {
                        description = "Icon theme name.";
                        type = lib.types.nullOr lib.types.str;
                        default = settings.icons.name;
                    };
                    package = lib.mkOption {
                        description = "Package providing the icon theme.";
                        type = lib.types.nullOr lib.types.package;
                        default = settings.icons.package;
                    };
                };
            };

            config = {
                environment.sessionVariables = {
                    XDG_ICON_DIR = "${cfg.icons.package}/share/icons/${cfg.icons.name}";
                    XCURSOR_THEME = cfg.cursor.name;
                    XCURSOR_SIZE = toString cfg.cursor.size;
                };
                environment.systemPackages = [
                    cfg.icons.package
                    cfg.cursor.package
                ];
            };
        };
}
