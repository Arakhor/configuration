{ niri, ... }:
{

  universal.imports = [ niri.nixosModules.niri ];

  personal =
    {
      homeConfig,
      nixosConfig,
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
        libnotify
        wl-clipboard-rs
        wayland-utils
        libsecret
        cage
        gamescope
        xwayland-satellite
      ];

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
            "org.freedesktop.impl.portal.Settings" = [ "darkman" ];
          };
        };
        extraPortals = with pkgs; [
          darkman
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
        ];

        xdgOpenUsePortal = true;
      };

      lib.niri = {
        actions = lib.mergeAttrsList (
          map (name: { ${name} = niri.lib.kdl.magic-leaf name; }) (import "${niri}/memo-binds.nix")
        );
      };

      home.imports =
        let
          cfg = homeConfig.programs.niri;
        in
        [
          niri.lib.internal.settings-module

          {
            options.programs.niri = {
              enable = lib.mkEnableOption "niri";
              package = lib.mkOption {
                type = lib.types.package;
                default = pkgs.niri-stable;
                description = "The niri package to use.";
              };
              extraConfig = lib.mkOption {
                type = lib.types.lines;
                description = "Extra lines to add after config validation.";
                default = "";
              };
            };

            config = lib.mkIf cfg.enable {
              packages = [ cfg.package ];
              file.xdg_config."niri/config.kdl".text = lib.concatLines [
                (builtins.readFile (niri.lib.internal.validated-config-for pkgs cfg.package cfg.finalConfig))
                cfg.extraConfig
              ];
            };
          }

          {
            config.programs.niri = {
              enable = lib.mkForce nixosConfig.programs.niri.enable;
              package = lib.mkForce nixosConfig.programs.niri.package;
            };
          }

          {
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
                  zoom = 0.7;
                  workspace-shadow.enable = false;
                };

                layout = {
                  background-color = "transparent";
                  gaps = 4;
                  always-center-single-column = true;
                  center-focused-column = "on-overflow";
                  default-column-display = "tabbed";
                  empty-workspace-above-first = true;

                  border = {
                    enable = true;
                    width = 2;
                  };

                  focus-ring.enable = false;

                  shadow.enable = false;

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

                animations.window-resize.custom-shader = # kdl
                  ''
                    vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
                      vec3 coords_next_geo = niri_curr_geo_to_next_geo * coords_curr_geo;

                      vec3 coords_stretch = niri_geo_to_tex_next * coords_curr_geo;
                      vec3 coords_crop = niri_geo_to_tex_next * coords_next_geo;

                      // We can crop if the current window size is smaller than the next window
                      // size. One way to tell is by comparing to 1.0 the X and Y scaling
                      // coefficients in the current-to-next transformation matrix.
                      bool can_crop_by_x = niri_curr_geo_to_next_geo[0][0] <= 1.0;
                      bool can_crop_by_y = niri_curr_geo_to_next_geo[1][1] <= 1.0;

                      vec3 coords = coords_stretch;
                      if (can_crop_by_x)
                          coords.x = coords_crop.x;
                      if (can_crop_by_y)
                          coords.y = coords_crop.y;

                      vec4 color = texture2D(niri_tex_next, coords.st);

                      // However, when we crop, we also want to crop out anything outside the
                      // current geometry. This is because the area of the shader is unspecified
                      // and usually bigger than the current geometry, so if we don't fill pixels
                      // outside with transparency, the texture will leak out.
                      //
                      // When stretching, this is not an issue because the area outside will
                      // correspond to client-side decoration shadows, which are already supposed
                      // to be outside.
                      if (can_crop_by_x && (coords_curr_geo.x < 0.0 || 1.0 < coords_curr_geo.x))
                          color = vec4(0.0);
                      if (can_crop_by_y && (coords_curr_geo.y < 0.0 || 1.0 < coords_curr_geo.y))
                          color = vec4(0.0);

                      return color;
                    }
                  '';

                layer-rules = [
                  {
                    matches = [ { namespace = "dms:blurwallpaper"; } ];
                    place-within-backdrop = true;
                  }
                ];

                window-rules = [
                  {
                    tiled-state = true;
                    draw-border-with-background = false;
                    clip-to-geometry = true;
                    geometry-corner-radius =
                      let
                        r = 20.0;
                      in
                      {
                        top-left = r;
                        top-right = r;
                        bottom-left = r;
                        bottom-right = r;
                      };
                  }
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
                      "Mod+T".action = spawn "ghostty" "+new-window";
                      "Mod+B".action = spawn "firefox";

                      # "Mod+Shift+S".action = screenshot;
                      # "Print".action.screenshot-screen = [ ];
                      # "Mod+Print".action = screenshot-window;

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
                      suffixes."H" = "column-left";
                      suffixes."J" = "window-down";
                      suffixes."K" = "window-up";
                      suffixes."L" = "column-right";
                      prefixes."Mod" = "focus";
                      prefixes."Mod+Ctrl" = "move";
                      prefixes."Mod+Shift" = "focus-monitor";
                      prefixes."Mod+Shift+Ctrl" = "move-window-to-monitor";
                      substitutions."monitor-column" = "monitor";
                      substitutions."monitor-window" = "monitor";
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
                    (binds {
                      suffixes."D" = "workspace-down";
                      suffixes."U" = "workspace-up";
                      prefixes."Mod" = "focus";
                      prefixes."Mod+Ctrl" = "move-window-to";
                      prefixes."Mod+Shift" = "move";
                    })
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
          }
        ];
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
      outputs."eDP-1".scale = 2.;
    };
  };
}
