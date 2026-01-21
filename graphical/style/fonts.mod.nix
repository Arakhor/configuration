{
    graphical =
        {
            pkgs,
            lib,
            config,
            ...
        }:
        let
            cfg = config.style.fonts;
        in
        {
            options.style.fonts =
                let
                    mkFontOption =
                        {
                            name,
                            package,
                        }:
                        {
                            name = lib.mkOption {
                                type = lib.types.str;
                                default = name;
                                description = "Name of the font family.";
                            };

                            package = lib.mkOption {
                                type = lib.types.nullOr lib.types.package;
                                default = package;
                                description = "Package providing the font.";
                            };
                        };
                in
                {
                    serif = mkFontOption {
                        name = "IBM Plex Serif";
                        package = pkgs.ibm-plex;
                    };

                    sansSerif = mkFontOption {
                        name = "IBM Plex Sans";
                        package = pkgs.ibm-plex;
                    };

                    monospace =
                        mkFontOption {
                            name = "Lilex";
                            package = pkgs.lilex;
                        }
                        // {
                            features = lib.mkOption {
                                description = "OpenType features to enable for the font in supported applications.";
                                type = lib.types.listOf lib.types.str;
                                default = [
                                    "calt"
                                    "ss02"
                                    "ss04"
                                ];
                            };
                        };

                    emoji = mkFontOption {
                        name = "Noto Color Emoji";
                        package = pkgs.noto-fonts-color-emoji;
                    };
                };

            config = {
                fonts = {
                    fontDir = {
                        enable = true;
                        decompressFonts = true;
                    };
                    packages = with pkgs; [
                        cfg.monospace.package
                        cfg.serif.package
                        cfg.sansSerif.package
                        cfg.emoji.package

                        noto-fonts
                        nerd-fonts.symbols-only
                    ];
                    fontconfig = {
                        enable = true;
                        defaultFonts =
                            let
                                addAll = builtins.mapAttrs (
                                    _: preferred: [
                                        "Symbols Nerd Font"
                                        preferred
                                        "Noto Sans Symbols"
                                        "Noto Sans Symbols 2"
                                        "Noto Color Emoji"
                                    ]
                                );
                            in
                            addAll {
                                serif = cfg.serif.name;
                                sansSerif = cfg.sansSerif.name;
                                monospace = cfg.monospace.name;
                                emoji = cfg.emoji.name;
                            };
                    };
                };
                preserveHome.directories = [ ".cache/fontconfig" ];
            };
        };
}
