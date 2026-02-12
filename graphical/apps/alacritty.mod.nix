{
    graphical =
        {
            config,
            pkgs,
            lib,
            ...
        }:
        {
            environment.systemPackages = [
                pkgs.alacritty
                # Modify the desktop entry to comply with the xdg-terminal-exec spec
                # https://gitlab.freedesktop.org/terminal-wg/specifications/-/merge_requests/3
                (lib.hiPrio (
                    pkgs.runCommand "alacritty-desktop-modify" { } ''
                        mkdir -p $out/share/applications
                        substitute ${pkgs.alacritty}/share/applications/Alacritty.desktop $out/share/applications/Alacritty.desktop \
                          --replace-fail "Type=Application" "Type=Application
                        X-TerminalArgAppId=--class
                        X-TerminalArgDir=--working-directory
                        X-TerminalArgHold=--hold
                        X-TerminalArgTitle=--title"
                    ''
                ))
            ];

            style.dynamic.templates.alacritty =
                let
                    keys = config.lib.style.genMatugenKeys { };
                    tomlFormat = pkgs.formats.toml { };
                in
                with keys;
                {
                    target = ".config/alacritty/themes/matugen.toml";
                    source = tomlFormat.generate "matugen-alacritty.toml" {
                        colors = {
                            transparent_background_colors = true;
                            normal = {
                                black = surface_container;
                                red = error;
                                green = success;
                                yellow = warning;
                                blue = primary;
                                magenta = tertiary;
                                cyan = secondary;
                                white = on_surface_variant;
                            };
                            bright = {
                                black = outline;
                                red = error;
                                green = success;
                                yellow = warning;
                                blue = primary;
                                magenta = tertiary;
                                cyan = secondary;
                                white = on_surface;
                            };
                            cursor = {
                                text = on_primary;
                                cursor = primary;
                            };
                            primary = {
                                background = surface;
                                foreground = on_surface;
                            };
                            selection = {
                                background = primary_container;
                                text = on_primary_container;
                            };
                        };
                    };
                };

            maid-users.file.xdg_config."alacritty/alacritty.toml".source =
                let
                    tomlFormat = pkgs.formats.toml { };

                    alacrittyConfig = {
                        general.import = [ ("~/" + config.style.dynamic.templates.alacritty.target) ];

                        # general.import = [ "${pkgs.alacritty-theme}/share/alacritty-theme/tokyo_night_enhanced.toml" ];

                        colors.draw_bold_text_with_bright_colors = false;
                        mouse.hide_when_typing = true;
                        cursor.style = {
                            blinking = "On";
                            shape = "Beam";
                        };
                        env.TERM = "xterm-256color";
                        font = {
                            normal.family = config.style.fonts.monospace.name;
                            size = 11.5;
                            builtin_box_drawing = false;
                            offset.y = 10;
                            glyph_offset.y = 5;
                        };
                        terminal = {
                            osc52 = "CopyPaste";
                        };
                        scrolling.history = 10000;
                        window = {
                            padding = {
                                x = config.style.gapSize;
                                y = config.style.gapSize;
                            };
                            dynamic_padding = true;
                            decorations = "None";
                            opacity = config.style.opacity;
                            dynamic_title = true;
                        };
                    };
                in
                (tomlFormat.generate "alacritty.toml" alacrittyConfig);
        };
}
