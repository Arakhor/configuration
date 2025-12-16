{ niri, ... }:
{
  universal.imports = [ niri.nixosModules.niri ];

  graphical =
    {
      homeConfig,
      pkgs,
      lib,
      ...
    }:
    {
      programs.niri.enable = true;
      programs.niri.package = pkgs.niri-unstable;
      nixpkgs.overlays = [ niri.overlays.niri ];
      environment.variables.NIXOS_OZONE_WL = "1";

      systemd.user.services.niri-flake-polkit.enable = false;

      environment.systemPackages = with pkgs; [
        alacritty
        libnotify
        wl-clipboard
        wayland-utils
        libsecret
        cage
        gamescope
        xwayland-satellite
      ];

      xdg.terminal-exec = {
        enable = true;
        settings.niri = lib.singleton "com.mitchellh.ghostty.desktop";
      };

      xdg.portal = {
        enable = true;
        config = {
          niri = {
            default = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.Access" = [ "gtk" ];
            "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          };
        };
        extraPortals = with pkgs; [
          gnome-keyring
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
        ];
        xdgOpenUsePortal = true;
      };

      home = {
        programs.niri.settings =
          with lib;
          let
            binds =
              {
                suffixes,
                prefixes,
                substitutions ? { },
              }:
              let
                replacer = replaceStrings (attrNames substitutions) (attrValues substitutions);
                format =
                  prefix: suffix:
                  let
                    actual-suffix =
                      if isList suffix.action then
                        {
                          action = head suffix.action;
                          args = tail suffix.action;
                        }
                      else
                        {
                          inherit (suffix) action;
                          args = [ ];
                        };

                    action = replacer "${prefix.action}-${actual-suffix.action}";
                  in
                  {
                    name = "${prefix.key}+${suffix.key}";
                    value.action.${action} = actual-suffix.args;
                  };
                pairs =
                  attrs: fn:
                  concatMap (
                    key:
                    fn {
                      inherit key;
                      action = attrs.${key};
                    }
                  ) (attrNames attrs);
              in
              listToAttrs (pairs prefixes (prefix: pairs suffixes (suffix: [ (format prefix suffix) ])));
          in
          {
            hotkey-overlay.skip-at-startup = true;
            prefer-no-csd = true;
            clipboard.disable-primary = true;

            screenshot-path = "~/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S.png";
            config-notification.disable-failed = true;
            debug.honor-xdg-activation-with-invalid-serial = true;

            cursor = {
              hide-when-typing = true;
            };

            # switch-events =
            #   let
            #     sh = spawn "sh" "-c";
            #   in
            #   {
            #     tablet-mode-on.action = sh "notify-send tablet-mode-on";
            #     tablet-mode-off.action = sh "notify-send tablet-mode-off";
            #     lid-open.action = sh "notify-send lid-open";
            #     lid-close.action = sh "notify-send lid-close";
            #   };

            overview = {
              zoom = 0.5;
              workspace-shadow.enable = true;
            };

            layout = {
              always-center-single-column = true;
              default-column-display = "tabbed";
              empty-workspace-above-first = true;

              border.enable = true;
              focus-ring.enable = false;

              shadow = {
                enable = true;
                softness = 20;
                spread = 2;
                offset = {
                  x = 0;
                  y = 4;
                };
              };

              tab-indicator = {
                position = "right";
                hide-when-single-tab = true;
                place-within-column = true;
                gap = -16;
                width = 4;
                length.total-proportion = 0.3;
                corner-radius = 8;
                gaps-between-tabs = 2;
              };
            };

            gestures.dnd-edge-view-scroll = {
              trigger-width = 64;
              delay-ms = 250;
              max-speed = 12000;
            };

            animations.window-resize.custom-shader = builtins.readFile ./resize.glsl;

            window-rules = [
              {
                matches = [
                  {
                    app-id = "^firefox$";
                    title = "^Picture-in-Picture$";
                  }
                ];
                open-focused = false;
                open-floating = true;
                default-floating-position = {
                  x = 32;
                  y = 32;
                  relative-to = "bottom-right";
                };
                default-column-width.fixed = 480;
                default-window-height.fixed = 270;
              }
            ];

            binds =
              with homeConfig.lib.niri.actions;
              let
                playerctl = spawn "${pkgs.playerctl}/bin/playerctl";
              in
              lib.attrsets.mergeAttrsList [
                {
                  "XF86AudioPlay".action = playerctl "play-pause";
                  "XF86AudioStop".action = playerctl "pause";
                  "XF86AudioPrev".action = playerctl "previous";
                  "XF86AudioNext".action = playerctl "next";
                }
                {
                  "Mod+T".action = spawn-sh "ghostty +new-window";

                  "Mod+Shift+S".action.screenshot = [ ];
                  "Print".action.screenshot-screen = [ ];
                  "Mod+Print".action.screenshot-window = [ ];

                  "Mod+Insert".action = set-dynamic-cast-window;
                  "Mod+Shift+Insert".action = set-dynamic-cast-monitor;
                  "Mod+Delete".action = clear-dynamic-cast-target;

                  "Mod+Q".action = close-window;
                  "Mod+W".action = toggle-overview;

                  "Mod+Y".action = toggle-column-tabbed-display;

                  "Mod+Tab".action = focus-window-down-or-column-right;
                  "Mod+Shift+Tab".action = focus-window-up-or-column-left;
                }
                (binds {

                  # suffixes."J" = "window-down";
                  # suffixes."K" = "window-up";
                  suffixes."H" = "column-left";
                  suffixes."L" = "column-right";
                  prefixes."Mod" = "focus";
                  prefixes."Mod+Ctrl" = "move";
                  # prefixes."Mod+Shift" = "focus-monitor";
                  # prefixes."Mod+Shift+Ctrl" = "move-window-to-monitor";
                  # substitutions."monitor-column" = "monitor";
                  # substitutions."monitor-window" = "monitor";
                })
                {
                  "Mod+K".action = focus-window-or-workspace-up;
                  "Mod+J".action = focus-window-or-workspace-down;
                  "Mod+Ctrl+K".action = move-window-up-or-to-workspace-up;
                  "Mod+Ctrl+J".action = move-window-down-or-to-workspace-down;
                }
                {
                  "Mod+G".action = switch-focus-between-floating-and-tiling;
                  "Mod+Shift+G".action = toggle-window-floating;
                }
                (binds {
                  suffixes."A" = "first";
                  suffixes."E" = "last";
                  prefixes."Mod" = "focus-column";
                  prefixes."Mod+Ctrl" = "move-column-to";
                })
                # (binds {
                #     suffixes."D" = "workspace-down";
                #     suffixes."U" = "workspace-up";
                #     prefixes."Mod" = "focus";
                #     prefixes."Mod+Ctrl" = "move-window-to";
                #     prefixes."Mod+Shift" = "move";
                # })
                {
                  "Mod+I".action = consume-window-into-column;
                  "Mod+O".action = expel-window-from-column;

                  "Mod+Comma".action = consume-or-expel-window-left;
                  "Mod+Period".action = consume-or-expel-window-right;
                }
                {
                  "Mod+R".action = switch-preset-column-width;
                  "Mod+Shift+R".action = switch-preset-column-width-back;
                  # "Mod+F".action = maximize-column;
                  # "Mod+Shift+F".action = fullscreen-window;
                  "Mod+F".action = fullscreen-window;

                  "Mod+C".action = center-column;

                  "Mod+1".action = set-column-width "33.3333%";
                  "Mod+2".action = set-column-width "50%";
                  "Mod+3".action = set-column-width "66.6666%";
                  "Mod+4".action = set-column-width "100%";

                  "Mod+Minus".action = set-column-width "-10%";
                  "Mod+Plus".action = set-column-width "+10%";
                  "Mod+Shift+Minus".action = set-window-height "-10%";
                  "Mod+Shift+Plus".action = set-window-height "+10%";

                  "Mod+Shift+Escape".action = toggle-keyboard-shortcuts-inhibit;
                  "Mod+Shift+E".action = quit;
                  "Mod+Shift+P".action = power-off-monitors;

                  "Mod+Shift+Ctrl+T".action = toggle-debug-tint;
                }
              ];
          };
      };
    };

  xps.home = {
    programs.niri.settings = {
      layout = {
        preset-column-widths = [
          { proportion = 1.0 / 3.0; }
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
        ];
        default-column-width = {
          proportion = 1.0 / 2.0;
        };
      };
      # internal laptop display
      outputs."eDP-1".scale = 2.5;
    };
  };
}
