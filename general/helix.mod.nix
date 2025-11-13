{ helix, ... }:
{
  universal =
    {
      lib,
      nixosConfig,
      pkgs,
      ...
    }:
    let
      settings = {
        keys =
          let
            shared = {
              H = ":buffer-previous";
              L = ":buffer-next";

              space = {
                x = ":buffer-close";
                q = ":quit";
                w = ":write";
                Q = ":quit!";
                W = ":write!";

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

        theme = "custom";
      };

      theme = {
        inherits = "tokyonight";
        "ui.background" = { };
      };

      # Language and LSP config.
      languages = {
        language-server = {
          uwu-colors.command = lib.getExe pkgs.uwu-colors;
          gpt = {
            command = lib.getExe pkgs.helix-gpt;
            args = [
              "--handler"
              "copilot"
            ];
          };
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

        language = [
          {
            name = "nix";
            auto-format = true;
            language-servers = [
              "nixd"
              "nil"
              "uwu-colors"
              "gpt"
            ];
            indent = {
              tab-width = 2;
              unit = "  ";
            };
            formatter = {
              command = lib.getExe pkgs.nixfmt-rfc-style;
              args = [
                "-v"
                "-q"
                "--indent=2"
                "-s"
              ];
            };
          }

          {
            name = "nu";
            auto-format = true;
            language-servers = [
              "nu-lsp"
              "uwu-colors"
              "gpt"
            ];
            formatter = {
              command = lib.getExe pkgs.wrapped.topiary-nu;
              args = [
                "format"
                "--language"
                "nu"
              ];
            };
          }
        ];
      };

    in
    {
      nixpkgs.overlays = [ helix.overlays.default ];
      nix.settings = {
        extra-substituters = [ "https://helix.cachix.org" ];
        extra-trusted-public-keys = [ "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs=" ];
      };

      wrappers.topiary-nu =
        let
          topiary-nushell = builtins.fetchTree {
            type = "github";
            owner = "blindFS";
            repo = "topiary-nushell";
            rev = "7f836bc14e0a435240c190b89ea02846ac883632";
          };
          tree-sitter-nu = pkgs.tree-sitter.buildGrammar {
            language = "nu";
            version = "0.0.0+rev=d5c71a10";
            src = builtins.fetchTree {
              type = "github";
              owner = "nushell";
              repo = "tree-sitter-nu";
              rev = "d5c71a10b4d1b02e38967b05f8de70e847448dd1";
            };
            meta.homepage = "https://github.com/nushell/tree-sitter-nu";
          };
        in
        {
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
                        indent = "  ", # 4 spaces
                        extensions = ["nu"],
                        grammar.source.path = "${tree-sitter-nu}/parser"
                      },
                    },
                  }
                '';
            TOPIARY_LANGUAGE_DIR.value = "${topiary-nushell}/languages";
          };
        };

      environment.variables = {
        EDITOR = "hx";
        VISUAL = "hx";
      };

      home.packages = [ pkgs.helix ];
      home.file.xdg_config = {
        "helix/config.toml".source = ((pkgs.formats.toml { }).generate "config.toml" settings);
        "helix/languages.toml".source = ((pkgs.formats.toml { }).generate "config.toml" languages);
        "helix/themes/custom.toml".source = ((pkgs.formats.toml { }).generate "config.toml" theme);
      };
    };
}
