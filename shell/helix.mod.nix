{
    helix,
    topiary-nushell,
    nu-lint,
    ...
}:
{
    universal =
        {
            lib,
            config,
            pkgs,
            ...
        }:
        let
            defaultLangs = lib.importTOML "${helix}/languages.toml";

            tomlformat = pkgs.formats.toml { };

            settings = {
                keys =
                    let
                        shared = {
                            H = ":buffer-previous";
                            L = ":buffer-next";

                            A-j = [
                                "extend_to_line_bounds"
                                "delete_selection"
                                "paste_after"
                            ];
                            A-k = [
                                "extend_to_line_bounds"
                                "delete_selection"
                                "move_line_up"
                                "paste_before"
                            ];
                            A-h = [
                                "delete_selection"
                                "move_char_left"
                                "paste_before"
                            ];
                            A-l = [
                                "delete_selection"
                                "move_char_right"
                                "paste_after"
                            ];

                            space = {
                                x = ":buffer-close";

                                q = ":quit";
                                w = ":write";
                                Q = ":quit!";
                                W = ":write!";

                                u = {
                                    f = ":format"; # format using LSP formatter
                                    w = ":set whitespace.render all";
                                    W = ":set whitespace.render none";
                                };

                                e = [
                                    ":sh rm -f /tmp/unique-file"
                                    ":insert-output yazi '%{buffer_name}' --chooser-file=/tmp/unique-file"
                                    ":insert-output echo \"\x1b[?1049h\" > /dev/tty"
                                    ":open %sh{cat /tmp/unique-file}"
                                    ":redraw"
                                ];
                            };
                        };
                    in
                    {
                        normal = shared // { };
                        select = shared // { };
                        insert = { };
                    };

                editor = {
                    line-number = "relative";
                    default-yank-register = "+"; # system clipboard
                    completion-trigger-len = 1;
                    idle-timeout = 0;
                    cursorcolumn = true;
                    cursorline = true;
                    bufferline = "multiple";
                    popup-border = "all";
                    color-modes = true;
                    auto-format = true;
                    rainbow-brackets = true;

                    cursor-shape.insert = "bar";
                    cursor-shape.select = "block";

                    lsp.display-inlay-hints = true;
                    end-of-line-diagnostics = "hint";
                    inline-diagnostics.cursor-line = "error";
                    inline-diagnostics.other-lines = "disable";

                    scrolloff = 5;
                    soft-wrap.enable = false;
                    indent-guides.render = true;

                    statusline = {
                        left = [
                            "mode"
                            "spinner"
                            "version-control"
                            "diagnostics"
                        ];
                        center = [
                            "file-name"
                            "file-modification-indicator"
                        ];
                        right = [
                            "position"
                            "file-encoding"
                            "file-type"
                        ];

                        mode =
                            let
                                icon = "hx:";
                            in
                            {
                                normal = "${icon}NORMAL";
                                insert = "${icon}INSERT";
                                select = "${icon}SELECT";
                            };
                    };
                };

                theme = "matugen";
            };

            # Language and LSP config.
            languages = {
                language-server = {
                    hx-lsp.command = lib.getExe pkgs.hx-lsp;
                    nu-lint = {
                        command = lib.getExe pkgs.nu-lint;
                        args = [ "--lsp" ];
                    };
                    nixd = {
                        command = lib.getExe pkgs.nixd;
                        args = [ "--semantic-tokens=true" ];
                        config.nixd =
                            let
                                flake = "(builtins.getFlake \"${config.programs.nh.flake}\")";
                                host = "${flake}.nixosConfigurations.${config.networking.hostName}";
                            in
                            {
                                nixpkgs.expr = "${host}.config.nixpkgs";
                                options = {
                                    nixos.expr = "${host}.options";
                                };
                            };
                    };
                };

                language =
                    # Common configuration for all languages
                    map
                        (
                            lang:
                            lang
                            // {
                                language-servers = lib.unique ((lang.language-servers or [ ]) ++ [ "hx-lsp" ]);
                                auto-format = true;
                            }
                        )
                        (
                            # Get default language.toml from repo
                            defaultLangs.language
                            # Overrides for specific languages
                            ++ [
                                {
                                    name = "nix";
                                    indent = {
                                        tab-width = 4;
                                        unit = "    ";
                                    };
                                    language-servers = [
                                        "nixd"
                                        "nil"
                                    ];
                                    formatter = {
                                        command = lib.getExe pkgs.nixfmt;
                                        args = [ "--indent=4" ];
                                    };
                                }
                                {
                                    name = "nu";
                                    language-servers = [
                                        "nu-lint"
                                        "nu-lsp"
                                    ];
                                    formatter = {
                                        command = lib.getExe pkgs.topiary-nushell;
                                        args = [
                                            "format"
                                            "--language"
                                            "nu"
                                        ];
                                    };
                                }
                            ]
                        );
            };
        in
        {
            nixpkgs.overlays = [
                helix.overlays.default
                (_: _: {
                    topiary-nushell = topiary-nushell.packages.${pkgs.stdenv.hostPlatform.system}.default;
                    nu-lint = nu-lint.packages.${pkgs.stdenv.hostPlatform.system}.default;
                })
            ];

            nix.settings = {
                substituters = [ "https://helix.cachix.org" ];
                trusted-public-keys = [ "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs=" ];
            };

            maid-users.file.xdg_config = {
                "helix/config.toml".source = tomlformat.generate "helix-config" settings;
                "helix/languages.toml".source = tomlformat.generate "helix-languages" languages;
            };

            environment.sessionVariables.EDITOR = "hx";

            wrappers.helix = {
                basePackage = pkgs.helix;
                pathAdd = with pkgs; [
                    nixd
                    nil
                    nixfmt
                    vscode-langservers-extracted
                    pkgs.topiary-nushell
                ];
                prependFlags = [
                    "-c"
                    (tomlformat.generate "helix-config" settings)
                ];
            };
        };

    graphical =
        { config, pkgs, ... }:
        {
            style.dynamic.templates.helix =
                let
                    tomlformat = pkgs.formats.toml { };
                    keys = config.lib.style.genMatugenKeys { };
                in
                with keys;
                {
                    target = ".config/helix/themes/matugen.toml";
                    source = tomlformat.generate "matugen-helix.toml" {
                        "attribute".fg = on_surface;
                        "label".fg = error;
                        "namespace".fg = tertiary;
                        "constructor".fg = tertiary;
                        "tag".fg = tertiary;
                        "type".fg = tertiary;

                        "comment" = {
                            fg = outline;
                            modifiers = [ "italic" ];
                        };

                        "constant".fg = primary;
                        "constant.builtin".fg = on_surface;

                        "function".fg = tertiary;

                        "keyword".fg = error;
                        "keyword.control.conditional" = {
                            fg = error;
                            modifiers = [ "italic" ];
                        };

                        "operator".fg = on_surface;

                        "punctuation".fg = outline;

                        "special".fg = primary;
                        "string".fg = secondary;

                        "variable".fg = on_surface;
                        "variable.builtin".fg = error;
                        "variable.parameter".fg = on_surface;
                        "variable.other.member".fg = primary;

                        "rainbow" = [
                            primary
                            secondary
                            tertiary
                            success
                            warning
                            error
                        ];

                        "diagnostic.error".underline = {
                            color = error;
                            style = "curl";
                        };
                        "diagnostic.hint".underline = {
                            color = secondary;
                            style = "curl";
                        };
                        "diagnostic.info".underline = {
                            color = primary;
                            style = "curl";
                        };
                        "diagnostic.warning".underline = {
                            color = warning;
                            style = "curl";
                        };
                        "diagnostic.unnecessary".modifiers = [ "dim" ];
                        "diagnostic.deprecated".modifiers = [ "crossed_out" ];

                        "diff.plus".fg = success;
                        "diff.delta".fg = tertiary;
                        "diff.minus".fg = error;

                        "info".fg = primary;
                        "hint".fg = secondary;
                        "warning".fg = warning;
                        "error".fg = error;

                        "markup.heading.1".fg = primary;
                        "markup.heading.2".fg = secondary;
                        "markup.heading.3".fg = tertiary;
                        "markup.heading.4".fg = success;
                        "markup.heading.5".fg = warning;
                        "markup.heading.6".fg = error;

                        "markup.normal.completion" = {
                            bg = surface_container;
                            fg = on_surface;
                        };
                        "markup.normal.hover" = {
                            bg = surface_container_high;
                            fg = on_surface;
                        };
                        "markup.raw.inline.completion" = {
                            bg = surface_container;
                            fg = on_surface;
                        };
                        "markup.raw.inline.hover" = {
                            bg = surface_container_high;
                            fg = on_surface;
                        };

                        "ui.background" = {
                            fg = on_surface;
                            bg = surface;
                        };
                        "ui.background.separator".fg = outline_variant;

                        "ui.bufferline" = {
                            bg = surface_container_low;
                            fg = on_surface_variant;
                        };
                        "ui.bufferline.active" = {
                            fg = on_surface;
                            underline = {
                                color = primary;
                                style = "line";
                            };
                        };
                        "ui.bufferline.inactive" = {
                            bg = surface_container_low;
                            fg = on_surface_variant;
                        };

                        "ui.cursor" = {
                            bg = secondary;
                            fg = on_secondary;
                        };
                        "ui.cursor.match" = {
                            bg = primary_container;
                            fg = on_primary_container;
                        };
                        "ui.cursor.primary" = {
                            bg = primary;
                            fg = on_primary;
                        };
                        "ui.cursorcolumn".bg = surface_container_high;
                        "ui.cursorline".bg = surface_container_high;

                        "ui.debug.active" = {
                            bg = primary;
                            fg = on_primary;
                        };
                        "ui.debug.breakpoint" = {
                            bg = error;
                            fg = on_error;
                        };
                        "ui.gutter" = {
                            bg = surface_container_lowest;
                        };
                        "ui.gutter.selected" = {
                            bg = surface_container_low;
                        };
                        "ui.help" = {
                            bg = surface;
                            fg = on_surface;
                        };
                        "ui.highlight" = {
                            bg = primary_container;
                            fg = on_primary_container;
                        };
                        "ui.highlight.frameline" = {
                            fg = primary;
                        };

                        "ui.linenr".fg = outline_variant;
                        "ui.linenr.selected".fg = primary;

                        "ui.menu" = {
                            bg = surface_container;
                            fg = on_surface;
                        };
                        "ui.menu.scroll" = {
                            bg = surface_container_high;
                            fg = on_surface;
                        };
                        "ui.menu.selected" = {
                            bg = primary;
                            fg = on_primary;
                        };

                        "ui.picker.header" = {
                            bg = surface_container_highest;
                            fg = on_surface;
                        };
                        "ui.picker.header.column" = {
                            bg = surface_container_high;
                            fg = on_surface;
                        };
                        "ui.picker.header.column.active" = {
                            bg = primary_container;
                            fg = on_primary_container;
                        };
                        "ui.popup" = {
                            bg = surface_container_high;
                            fg = on_surface;
                        };
                        "ui.popup.info" = {
                            bg = surface_container;
                            fg = outline;
                        };
                        "ui.selection" = {
                            bg = secondary_container;
                            fg = on_secondary_container;
                        };
                        "ui.selection.primary" = {
                            bg = primary_container;
                            fg = on_primary_container;
                        };

                        "ui.statusline" = {
                            bg = surface_container_lowest;
                            fg = on_surface;
                        };
                        "ui.statusline.inactive" = {
                            bg = surface_container_highest;
                            fg = on_surface;
                        };
                        "ui.statusline.insert" = {
                            bg = secondary;
                            fg = on_secondary;
                        };
                        "ui.statusline.normal" = {
                            bg = primary;
                            fg = on_primary;
                        };
                        "ui.statusline.select" = {
                            bg = tertiary;
                            fg = on_tertiary;
                        };
                        "ui.statusline.separator".fg = outline;

                        "ui.text".fg = on_background;
                        "ui.text.directory".fg = primary;
                        "ui.text.focus" = {
                            bg = surface_container_high;
                            fg = on_surface;
                        };
                        "ui.text.inactive" = {
                            bg = surface_container_low;
                            fg = on_surface_variant;
                        };

                        "ui.virtual".fg = outline_variant;
                        "ui.virtual.jump-label" = {
                            bg = tertiary_container;
                            fg = on_tertiary_container;
                        };
                        "ui.window".fg = outline;
                    };
                    hooks.after = "if (${pkgs.procps}/bin/pgrep hx | is-not-empty) { ${pkgs.procps}/bin/pkill -USR1 hx }";
                };
        };
}
