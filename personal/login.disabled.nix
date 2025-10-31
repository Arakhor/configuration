{ niri, ... }:
{
  personal.imports = [
    (
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        options.login.tuigreet-width.proportion = lib.mkOption {
          type = lib.types.float;
        };

        config =
          let
            maid-config = config.users.users.arakhor.maid;
            niri-cfg-modules = lib.evalModules {
              modules = [
                niri.lib.internal.settings-module
                (
                  let
                    cfg = maid-config.programs.niri.settings;
                  in
                  {
                    programs.niri.settings = {
                      hotkey-overlay.skip-at-startup = true;

                      input = cfg.input;
                      # causes a deprecation warning otherwise
                      cursor = builtins.removeAttrs cfg.cursor [ "hide-on-key-press" ];
                      outputs = cfg.outputs // {
                        "HDMI-A-1".enable = false;
                      };

                      layout = cfg.layout // {
                        center-focused-column = "always";
                        default-column-width.proportion = config.login.tuigreet-width.proportion;
                      };

                      spawn-at-startup = [
                        {
                          command = [
                            (lib.getExe pkgs.swaybg)
                            "-i"
                            "${config.wallpaper.blurred}"
                          ];
                        }

                      ];

                      window-rules = [
                        {
                          # open-maximized = true;
                          draw-border-with-background = false;
                          clip-to-geometry = true;
                          geometry-corner-radius = {
                            top-left = 8.0;
                            top-right = 8.0;
                            bottom-left = 8.0;
                            bottom-right = 8.0;
                          };
                        }
                      ];
                    };
                  }
                )
              ];
            };

            niri-config =
              niri.lib.internal.validated-config-for pkgs config.programs.niri.package
                niri-cfg-modules.config.programs.niri.finalConfig;

            alacritty-config = {
              font = {
                normal.family = "Aporetic Sans Mono";
                size = 18;
              };
              window = {
                padding = {
                  x = 20;
                  y = 20;
                };
                dynamic_padding = true;
                decorations = "None";
                opacity = 0.9;
              };
              colors = {
                transparent_background_colors = true;
                draw_bold_text_with_bright_colors = false;
              };
            }
            // (lib.importTOML "${pkgs.alacritty-theme}/share/alacritty-theme/kanagawa_wave.toml");
          in
          {
            services.greetd = {
              enable = true;
              useTextGreeter = true;
              settings = {
                default_session =
                  let
                    # These are like that, because we want to use the currently-installed versions.
                    # If they are store paths, they might get outdated.
                    # This mainly concerns high-uptime usage.
                    # That's because greetd doesn't restart when system services are restarted.
                    # So you get new versions of mesa, new niri to match, but greetd still uses the old ones.
                    # and then you get a black screen when you log out.
                    # This is because the greeter owns the session, so restarting the greeter restarts the session.
                    niri = "/run/current-system/sw/bin/niri";
                    niri-session = "/run/current-system/sw/bin/niri-session";
                    alacritty = lib.getExe pkgs.alacritty;

                    tuigreet = lib.getExe pkgs.tuigreet;
                    systemctl = lib.getExe' maid-config.systemd.package "systemctl";
                  in
                  {
                    command = builtins.concatStringsSep " " [
                      niri
                      "-c"
                      niri-config
                      "--"
                      "/usr/bin/env"
                      # shader cache for the Blazingly Fast Terminal Emulators
                      "XDG_CACHE_HOME=/tmp/greeter-cache"
                      alacritty
                      "--config-file"
                      ((pkgs.formats.toml { }).generate "alacritty.toml" alacritty-config)
                      "-e"
                      # disgusting nested script hack
                      (pkgs.writeScript "greet-cmd" ''
                        # note: this part runs as greeter
                        ${tuigreet} --remember --cmd ${pkgs.writeScript "init-session" ''
                          # but this part is run as logged in user
                          # so here we're trying to stop a previous niri session
                          ${systemctl} --user is-active niri.service && ${systemctl} --user stop niri.service
                          # and then we start a new one
                          ${niri-session}
                        ''}
                        # this exits the greeter's niri (otherwise it hangs around for some seconds until greetd kills it)
                        ${niri} msg action quit --skip-confirmation
                        # only after this point does init-session run
                      '')
                    ];
                    user = "greeter";
                  };
              };
            };
          };
      }
    )

    {
      preserveSystem.directories = [
        {
          directory = "/var/cache/tuigreet";
          user = "greeter";
          group = "greeter";
          mode = "0755";
        }
      ];
    }
  ];

  xps.login.tuigreet-width.proportion = 0.5;

}
