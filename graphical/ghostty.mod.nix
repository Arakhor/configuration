{ ghostty, ... }:
{
  graphical =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      desktopId = "com.mitchellh.ghostty";
      package = pkgs.ghostty;
      keyValueSettings = {
        listsAsDuplicateKeys = true;
        mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
      };
      keyValue = pkgs.formats.keyValue keyValueSettings;
    in
    {
      nixpkgs.overlays = [ ghostty.overlays.default ];
      nix.settings = {
        substituters = [ "https://ghostty.cachix.org" ];
        trusted-public-keys = [ "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns=" ];
      };

      home = {
        packages = [
          package
          (lib.hiPrio (
            pkgs.runCommand "ghostty-desktop-modify" { } ''
              mkdir -p $out/share/applications
              substitute ${pkgs.ghostty}/share/applications/${desktopId}.desktop $out/share/applications/${desktopId}.desktop \
                --replace-fail "Type=Application" "Type=Application
              X-TerminalArgAppId=--class
              X-TerminalArgDir=--working-directory
              X-TerminalArgHold=--wait-after-command
              X-TerminalArgTitle=--title"
            ''
          ))
        ];
        systemd.packages = [ package ];

        file.xdg_config."ghostty/config".source = keyValue.generate "ghostty-config" {
          config-file = "themes/dankcolors";

          font-family = "Monaspace Argon";
          font-family-italic = "Monaspace Radon";
          font-family-bold = "Monaspace Krypton";
          font-family-bold-italic = "Monaspace Xenon";

          font-style = "Medium";
          font-style-italic = "Medium";
          font-style-bold = "Medium";
          font-style-bold-italic = "Medium";

          font-feature = "+ss01,+ss02,+ss03,+ss04,+ss05,+ss06,+ss07,+ss08,+ss09,+ss10,+liga,+dlig,+calt";

          font-size = 9;
          adjust-cell-height = "40%";
          adjust-underline-position = "20%";

          shell-integration-features = "ssh-env";
          confirm-close-surface = false;

          background-opacity = 0.95;
          background-opacity-cells = true;

          mouse-hide-while-typing = true;
          quit-after-last-window-closed = true;
          quit-after-last-window-closed-delay = "5m";

          gtk-toolbar-style = "flat";
          gtk-tabs-location = "bottom";
          gtk-wide-tabs = false;
          window-decoration = false;
          window-theme = "ghostty";
          window-padding-color = "extend";
          linux-cgroup = "always";

          window-padding-x = 8;
          window-padding-y = 2;

          keybind = lib.concatLists [
            # unbind alt-num to get them passed into the term
            (map (i: "alt+${toString i}=unbind") (lib.range 0 9))
            (map (i: "alt+digit_${toString i}=unbind") (lib.range 0 9))
            # goto_tab 0-9
            (map (i: "ctrl+s>${toString i}=goto_tab:${toString i}") (lib.range 1 9))
            [
              "ctrl+s>0=last_tab"

              "ctrl+s>c=new_tab"
              "ctrl+s>x=close_surface"

              "ctrl+s>\\=new_split:right"
              "ctrl+s>-=new_split:down"

              "ctrl+s>h=goto_split:left"
              "ctrl+s>j=goto_split:bottom"
              "ctrl+s>k=goto_split:top"
              "ctrl+s>l=goto_split:right"

              "ctrl+s>shift+h=resize_split:left,10"
              "ctrl+s>shift+j=resize_split:down,10"
              "ctrl+s>shift+k=resize_split:up,10"
              "ctrl+s>shift+l=resize_split:right,10"

              "ctrl+s>r=reload_config"

              # send ctrl+s itself, by tapping it twice
              "ctrl+s>ctrl+s=text:\\x13"
            ]
          ];
        };
      };
    };
}
