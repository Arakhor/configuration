{ ghostty, ... }:
{
    personal = {
        nixpkgs.overlays = [ ghostty.overlays.default ];
        nix.settings = {
            extra-substituters = [ "https://ghostty.cachix.org" ];
            extra-trusted-public-keys = [ "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns=" ];
        };

        home =
            { pkgs, lib, ... }:
            let
                package = pkgs.ghostty;
                keyValueSettings = {
                    listsAsDuplicateKeys = true;
                    mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
                };
                keyValue = pkgs.formats.keyValue keyValueSettings;
            in
            {
                packages = [ package ];
                dbus.packages = [ package ];
                systemd.packages = [ package ];

                file.xdg_config."ghostty/shaders/cursor_blaze.glsl".source = ./cursor_blaze.glsl;

                file.xdg_config."ghostty/config".source = keyValue.generate "ghostty-config" {
                    font-family = "Berkeley Mono Medium UltraCondensed";
                    font-size = 15;
                    adjust-cell-height = "40%";
                    adjust-underline-position = "20%";

                    shell-integration-features = "ssh-env";
                    confirm-close-surface = false;

                    theme = "TokyoNight";
                    background = "#000000";

                    background-opacity = 0.8;
                    background-opacity-cells = true;

                    custom-shader = "shaders/cursor_blaze.glsl";

                    mouse-hide-while-typing = true;
                    quit-after-last-window-closed = true;
                    quit-after-last-window-closed-delay = "5m";

                    gtk-toolbar-style = "flat";
                    gtk-tabs-location = "bottom";
                    gtk-wide-tabs = false;
                    window-decoration = false;
                    window-theme = "ghostty";
                    linux-cgroup = "always";

                    window-padding-x = 6;
                    window-padding-y = 6;

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
                        ]
                    ];
                };
            };
    };
}
