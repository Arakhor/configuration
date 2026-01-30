{
    helix,
    nixd,
    nushell-nightly,
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
                                X = ":buffer-close!";
                                q = ":quit";
                                Q = ":quit!";
                                w = ":write";
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
                    # hx-lsp.command = lib.getExe pkgs.hx-lsp;

                    nu-lsp = {
                        command = lib.getExe config.programs.nushell.finalPackage;
                        args = [ "--lsp" ];
                    };

                    nu-lint = {
                        command = lib.getExe pkgs.nu-lint;
                        args = [ "--lsp" ];
                    };

                    nixd = {
                        command = lib.getExe config.wrappers.nixd.wrapped;
                        args = [ "--semantic-tokens=true" ];
                        config.nixd =
                            let
                                flake = "(builtins.getFlake (toString ${config.programs.nh.flake}))";
                                host = "${flake}.nixosConfigurations.${config.networking.hostName}";
                            in
                            {
                                nixpkgs.expr = "import ${flake}.inputs.nixpkgs { }";
                                options = {
                                    nixos.expr = "${host}.options";
                                    # maid-users.expr = "${host}.config.users.users.arakhor.maid.build.optionsDoc.optionsNix";
                                    wrappers.expr = "${host}.options.wrappers.type.getSubOptions []";
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
                                language-servers = lib.unique (
                                    (lang.language-servers or [ ])
                                    ++ [
                                        # "hx-lsp"
                                    ]
                                );
                                auto-format = true;
                                indent = {
                                    tab-width = 4;
                                    unit = "    ";
                                };
                            }
                        )
                        (
                            # Get default language.toml from repo
                            defaultLangs.language
                            # Overrides for specific languages
                            ++ [
                                {
                                    name = "nix";
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
                                        "nu-lsp"
                                        "nu-lint"
                                    ];
                                    formatter = {
                                        command = lib.getExe config.wrappers.topiary-nushell.wrapped;
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
                    # topiary-nushell = topiary-nushell.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
                    nil
                    config.wrappers.nixd.wrapped
                    vscode-langservers-extracted
                ];
                prependFlags = [
                    "-c"
                    (tomlformat.generate "helix-config" settings)
                ];
            };

            wrappers.topiary-nushell = {
                basePackage = pkgs.topiary;
                prependFlags = [ "--merge-configuration" ];
                env = {
                    TOPIARY_CONFIG_FILE.value =
                        let
                            inherit (nushell-nightly.packages.${pkgs.stdenv.hostPlatform.system}) tree-sitter-nu;
                        in
                        pkgs.writeText "languages.ncl"
                            # nickel
                            ''
                                {
                                  languages = {
                                    nu = {
                                      indent = "    ", # 4 spaces
                                      extensions = ["nu"],
                                      grammar.source.path = "${tree-sitter-nu}/parser"
                                    },
                                  },
                                }
                            '';
                    TOPIARY_LANGUAGE_DIR.value = "${topiary-nushell}/languages";
                };
            };

            wrappers.nixd = {
                basePackage = nixd.packages.${pkgs.stdenv.hostPlatform.system}.default;
                overrideAttrs = old: {
                    buildCommand = ''
                        ${old.buildCommand}
                        wrapProgram $out/bin/nixd \
                        --run ${
                            lib.escapeShellArg
                                # sh
                                ''
                                    export NIX_CONFIG="$(${lib.getExe pkgs.gnused} -E 's/ pipe-operator( |$)/ pipe-operators\1/' /etc/nix/nix.conf)
                                    $NIX_CONFIG"
                                ''
                        }
                    '';
                };
            };
        };

    graphical =
        { config, pkgs, ... }:
        {
            style.dynamic.templates.helix =
                let
                    tomlFormat = pkgs.formats.toml { };
                    keys = config.lib.style.genMatugenKeys { };
                in
                with keys;
                {
                    target = ".config/helix/themes/matugen.toml";

                    # Based on Github Dark
                    source = tomlFormat.generate "matugen-helix.toml" {
                        "attribute" = on_surface;
                        "keyword" = error;
                        "namespace" = warning;
                        "punctuation" = on_surface;
                        "operator" = secondary;
                        "special" = secondary;
                        "variable" = on_surface;
                        "variable.other.member" = primary;
                        "variable.builtin" = error;
                        "type" = warning;
                        "type.builtin" = primary;
                        "constructor" = tertiary;
                        "function" = tertiary;
                        "tag" = success;
                        "comment" = outline;
                        "constant" = primary;
                        "string" = secondary;
                        "label" = error;

                        # "comment" = {
                        #     fg = base03;
                        #     modifiers = [ "italic" ];
                        # };
                        # "operator" = base05;
                        # "variable" = base08;
                        # "constant.numeric" = base09;
                        # "constant" = base09;
                        # "attribute" = base09;
                        # "type" = base0a;
                        # "string" = base0b;
                        # "variable.other.member" = base0b;
                        # "constant.character.escape" = base0c;
                        # "function" = base0d;
                        # "constructor" = base0d;
                        # "special" = base0d;
                        # "keyword" = base0e;
                        # "label" = base0e;
                        # "namespace" = base0e;

                        "rainbow" = [
                            success
                            warning
                            error
                            primary
                            secondary
                            # tertiary
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

                        "diff.plus".fg = success_container;
                        "diff.delta".fg = warning_container;
                        "diff.minus".fg = error_container;

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

                        "ui.background" = "none";

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

                        "ui.gutter".bg = surface_container_lowest;
                        "ui.gutter.selected".bg = surface_container_low;
                        "ui.help".bg = surface_container;

                        "ui.highlight" = {
                            bg = primary_container;
                            fg = on_primary_container;
                        };
                        "ui.highlight.frameline".fg = primary;

                        "ui.linenr".fg = outline_variant;
                        "ui.linenr.selected".fg = primary;

                        "ui.menu" = {
                            bg = surface_container;
                            fg = on_surface;
                        };
                        "ui.menu.selected" = {
                            bg = primary_container;
                            fg = on_primary_container;
                        };
                        "ui.menu.scroll" = {
                            bg = surface_container_high;
                            fg = on_surface;
                        };

                        "ui.picker.header" = {
                            fg = primary;
                            modifiers = [ "bold" ];
                        };

                        "ui.popup".bg = surface_container;
                        "ui.popup.info".bg = surface_container_high;

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
                        "ui.statusline.insert" = {
                            bg = primary;
                            fg = on_primary;
                        };
                        "ui.statusline.normal" = {
                            bg = secondary;
                            fg = on_secondary;
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
