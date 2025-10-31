{
  personal.home = {
    programs.sherlock = {
      enable = false;
      systemd.enable = false;
      settings = {
        status_bar.enable = false;
        behavior.global_prefix = "niri msg action spawn --";
        caching.enable = true;
      };
      launchers = [
        {
          name = "Spotify";
          actions = [
            {
              exit = false;
              icon = "media-seek-forward";
              method = "inner.next";
              name = "Skip";
            }
            {
              exit = false;
              icon = "media-seek-backward";
              method = "inner.previous";
              name = "Previous";
            }
          ];
          args = { };
          async = true;
          binds = [
            {
              bind = "Return";
              callback = "playpause";
              exit = false;
            }
            {
              bind = "l";
              callback = "next";
              exit = false;
            }
            {
              bind = "h";
              callback = "previous";
              exit = false;
            }
          ];
          exit = true;
          home = "OnlyHome";
          priority = 1;
          shortcut = true;
          spawn_focus = false;
          type = "audio_sink";
        }

        {
          name = "Calculator";
          args = {
            capabilities = [
              "calc.math"
              "calc.units"
            ];
          };
          async = false;
          exit = true;
          home = "Search";
          on_return = "copy";
          priority = 1;
          shortcut = true;
          spawn_focus = true;
          type = "calculation";
        }

        {
          name = "App Launcher";
          alias = "app";
          args = { };
          async = false;
          exit = true;
          home = "Home";
          priority = 3;
          shortcut = true;
          spawn_focus = true;
          type = "app_launcher";
        }

        {
          name = "Kill Process";
          alias = "kill";
          async = false;
          exit = true;
          home = "Search";
          priority = 0;
          shortcut = true;
          spawn_focus = true;
          type = "process";
        }

        {
          name = "Web Search";
          alias = "kagi";
          args = {
            icon = "firefox";
            search_engine = "https://kagi.com/search?q={keyword}";
          };
          display_name = "Kagi";
          priority = 100;
          tag_start = "{keyword}";
          type = "web_launcher";
        }
      ];
    };
  };

  universal.home =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        mkIf
        mkEnableOption
        mkPackageOption
        mkOption
        types
        ;

      cfg = config.programs.sherlock;

      tomlFormat = pkgs.formats.toml { };
      jsonFormat = pkgs.formats.json { };
    in
    {
      options.programs.sherlock = {
        enable = mkEnableOption "sherlock launcher" // {
          description = ''
            Enable Sherlock, a fast and lightweight application launcher for Wayland.

            See <https://github.com/Skxxtz/sherlock> for more information.
          '';
        };

        package = mkPackageOption pkgs "sherlock" {
          default = "sherlock-launcher";
          nullable = true;
        };

        settings = mkOption {
          inherit (tomlFormat) type;
          default = { };
          description = ''
            Configuration for Sherlock.

            Written to `config.toml`.

            See <https://github.com/Skxxtz/sherlock/blob/main/docs/config.md> for available options.
          '';
          example = {
            theme = "dark";
            width = 500;
            max_results = 8;
          };
        };

        systemd.enable = lib.mkEnableOption "sherlock as a daemon";

        aliases = mkOption {
          inherit (jsonFormat) type;
          default = { };
          description = ''
            Defines custom aliases.

            Written to `sherlock_alias.json`.

            See <https://github.com/Skxxtz/sherlock/blob/main/docs/aliases.md> for more information.
          '';
          example = {
            "NixOS Wiki" = {
              name = "NixOS Wiki";
              icon = "nixos";
              exec = "firefox https://nixos.wiki/index.php?search=%s";
              keywords = "nix wiki docs";
            };
          };
        };

        ignore = mkOption {
          type = types.lines;
          default = "";
          description = ''
            A list of desktop entry IDs to ignore.

            Written to `sherlockignore`.

            See <https://github.com/Skxxtz/sherlock/blob/main/docs/sherlockignore.md> for more information.
          '';
          example = ''
            hicolor-icon-theme.desktop
            user-dirs.desktop
          '';
        };

        launchers = mkOption {
          inherit (jsonFormat) type;
          default = [ ];
          description = ''
            Defines fallback launchers.

            Written to `fallback.json`.

            See <https://github.com/Skxxtz/sherlock/blob/main/docs/launchers.md> for more information.
          '';
        };

        style = mkOption {
          type = types.lines;
          default = "";
          description = ''
            Custom CSS to style the Sherlock UI.

            Written to `main.css`.
          '';
          example = ''
            window {
              background-color: #2E3440;
            }
          '';
        };
      };
      config = mkIf cfg.enable {
        packages = mkIf (cfg.package != null) [ cfg.package ];

        file.xdg_config = {
          "sherlock/config.toml" = mkIf (cfg.settings != { }) {
            source = tomlFormat.generate "sherlock-config.toml" cfg.settings;
          };

          "sherlock/sherlock_alias.json" = mkIf (cfg.aliases != { }) {
            source = jsonFormat.generate "sherlock_alias.json" cfg.aliases;
          };

          "sherlock/fallback.json" = mkIf (cfg.launchers != [ ]) {
            source = jsonFormat.generate "sherlock-fallback.json" cfg.launchers;
          };

          "sherlock/sherlockignore" = mkIf (cfg.ignore != "") {
            text = cfg.ignore;
          };

          "sherlock/main.css" = mkIf (cfg.style != "") {
            text = cfg.style;
          };
        };

        systemd.services.sherlock = lib.mkIf cfg.systemd.enable {
          description = "Sherlock - App Launcher";
          unitConfig.X-Restart-Triggers = lib.mkMerge [
            (lib.mkIf (cfg.settings != { }) [ "${config.file.xdg_config."sherlock/config.toml".source}" ])
            (lib.mkIf (cfg.aliases != { }) [
              "${config.file.xdg_config."sherlock/sherlock_alias.json".source}"
            ])
            (lib.mkIf (cfg.launchers != [ ]) [ "${config.file.xdg_config."sherlock/fallback.json".source}" ])
            (lib.mkIf (cfg.ignore != "") [ "${config.file.xdg_config."sherlock/sherlockignore".source}" ])
            (lib.mkIf (cfg.style != "") [ "${config.file.xdg_config."sherlock/main.css".source}" ])
          ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            Environment = [ "DISPLAY=:0" ];
            ExecStart = "${lib.getExe cfg.package} --daemonize";
            Restart = "on-failure";
          };
        };
      };
    };
}
