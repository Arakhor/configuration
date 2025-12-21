inputs: {
  universal =
    {
      lib,
      nixosConfig,
      pkgs,
      ...
    }:

    let
      defaultLangs = lib.importTOML "${inputs.helix}/languages.toml";

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
          nixd = {
            command = lib.getExe pkgs.nixd;
            args = [ "--semantic-tokens=true" ];
            config.nixd =
              let
                f = "(builtins.getFlake \"/home/arakhor/configuration\")";
              in
              {
                nixpkgs.expr = "import ${f}.inputs.nixpkgs {}";
                options.nixos.expr = "${f}.nixosConfigurations.${nixosConfig.networking.hostName}.options";
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
                    "hx-lsp"
                  ]
                );
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
                  language-servers = [
                    "nixd"
                    "nil"
                  ];
                }
                {
                  name = "nu";
                  language-servers = [ "nu-lsp" ];
                }
              ]
            );
      };

    in
    {
      nixpkgs.overlays = [ inputs.helix.overlays.default ];
      nix.settings = {
        substituters = [ "https://helix.cachix.org" ];
        trusted-public-keys = [ "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs=" ];
      };

      environment.variables.EDITOR = "hx";

      packages = [
        pkgs.wrapped.helix

        (
          let
            topiary-nushell = inputs.topiary-nushell;
            tree-sitter-nu = inputs.nushell-nightly.packages.${pkgs.stdenv.hostPlatform.system}.tree-sitter-nu;
          in
          pkgs.mkWrapper {
            basePackage = pkgs.topiary;
            prependFlags = [ "--merge-configuration" ];
            env = {
              TOPIARY_CONFIG_FILE.value =
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
          }
        )
      ];

      home.file.xdg_config = {
        "helix/config.toml".source = tomlformat.generate "helix-config" settings;
        "helix/languages.toml".source = tomlformat.generate "helix-languages" languages;
      };

      wrapper-manager.wrappers.helix = {
        basePackage = pkgs.helix;
        pathAdd = with pkgs; [
          nixd
          nil
          vscode-langservers-extracted
        ];
        prependFlags = [
          "-c"
          (tomlformat.generate "helix-config" settings)
        ];
      };
    };
}
