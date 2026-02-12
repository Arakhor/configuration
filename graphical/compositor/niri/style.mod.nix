{
    graphical =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            inherit (config) style;
        in
        {

            programs.niri = {
                settings = {
                    prefer-no-csd = true;
                    overview.workspace-shadow.enable = false;

                    cursor = {
                        hide-when-typing = true;
                        theme = style.cursor.name;
                        size = style.cursor.size;
                    };

                    layout = {
                        gaps = style.gapSize;
                        struts.left = style.gapSize * 4;
                        struts.right = style.gapSize * 4;

                        background-color = "transparent";

                        focus-ring = {
                            enable = true;
                            width = style.borderWidth;
                        };

                        border.enable = false;
                        shadow.enable = false;

                        # tab-indicator = {
                        #     position = "right";
                        #     hide-when-single-tab = true;
                        #     place-within-column = true;
                        #     gap = -16;
                        #     width = 4;
                        #     length.total-proportion = 0.3;
                        #     corner-radius = 8;
                        #     gaps-between-tabs = 2;
                        # };
                    };

                    window-rules = [
                        {
                            geometry-corner-radius =
                                let
                                    r = style.cornerRadius * 1.0;
                                in
                                {
                                    top-left = r;
                                    top-right = r;
                                    bottom-left = r;
                                    bottom-right = r;
                                };
                            clip-to-geometry = true;
                            draw-border-with-background = false;
                            tiled-state = true;
                        }
                    ];
                };
                settings.includes = lib.mkAfter [
                    "matugen.kdl"
                ];
            };

            style.dynamic.templates.niri =
                with lib.kdl;
                with (config.lib.style.genMatugenKeys { });
                let
                    generateKdl = name: document: pkgs.callPackage lib.kdl.generator { inherit name document; };
                    borderLike = [
                        (leaf "active-color" primary)
                        (leaf "inactive-color" primary_container)
                        (leaf "urgent-color" tertiary)
                    ];
                in
                {
                    target = ".config/niri/matugen.kdl";
                    source = generateKdl "matugen-niri.kdl" [
                        (plain "layout" [
                            (plain "focus-ring" borderLike)
                            (plain "border" borderLike)
                            (plain "shadow" [ (leaf "color" "${shadow}80") ])
                            (plain "tab-indicator" [
                                (leaf "active-color" primary)
                                (leaf "inactive-color" primary_container)
                                (leaf "urgent-color" tertiary)
                            ])
                            (plain "insert-hint" [ (leaf "color" "${primary}80") ])
                        ])
                        (plain "overview" [
                            (leaf "backdrop-color" surface_container_lowest)
                        ])
                        (plain "recent-windows" [
                            (plain "highlight" [
                                (leaf "active-color" primary)
                                (leaf "urgent-color" tertiary)
                            ])
                        ])
                    ];
                };
        };
}
