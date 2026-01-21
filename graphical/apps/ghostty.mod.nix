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

            style.dynamic.templates.ghostty =
                let
                    keys = config.lib.style.genMatugenKeys { };
                in
                with keys;
                {
                    target = ".config/ghostty/themes/matugen";
                    source = keyValue.generate "ghostty-theme" {
                        palette = lib.imap0 (i: v: "${toString i}=${v}") [
                            surface_container
                            error
                            success
                            warning
                            primary
                            tertiary
                            secondary
                            on_surface
                            outline_variant
                            error
                            success
                            warning
                            primary
                            tertiary
                            secondary
                            on_surface_variant
                        ];
                        background = surface;
                        foreground = on_surface;
                        cursor-color = primary;
                        selection-background = primary_container;
                        selection-foreground = on_primary_container;
                    };
                    hooks.after = "pkill -SIGUSR2 ghostty";
                };

            maid-users = {
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

                file.xdg_config."ghostty/config".source = keyValue.generate "ghostty-config" {
                    bell-features = lib.concatStringsSep "," [
                        "system"
                        "attention"
                        "title"
                    ];

                    shell-integration-features = true;

                    background-opacity = config.style.opacity;
                    background-opacity-cells = true;

                    gtk-toolbar-style = "flat";
                    gtk-tabs-location = "bottom";
                    gtk-wide-tabs = false;

                    window-decoration = false;
                    window-theme = "ghostty";
                    window-padding-color = "extend";
                    window-padding-balance = true;
                    window-padding-x = config.style.gapSize / 2;
                    window-padding-y = config.style.gapSize / 2;

                    font-size = 10;
                    adjust-cell-height = "40%";
                    adjust-underline-position = "20%";

                    theme = "matugen";
                    font-family = config.style.fonts.monospace.name;

                    # font-family = "Monaspace Neon";
                    # font-family-italic = "Monaspace Radon";
                    # font-family-bold = "Monaspace Krypton";
                    # font-family-bold-italic = "Monaspace Xenon";

                    # font-style = "Medium";
                    # font-style-italic = "Medium";
                    # font-style-bold = "Medium";
                    # font-style-bold-italic = "Medium";

                    font-feature = config.style.fonts.monospace.features;

                    confirm-close-surface = false;

                    mouse-hide-while-typing = true;
                    quit-after-last-window-closed = true;
                    quit-after-last-window-closed-delay = "5m";
                    linux-cgroup = "always";

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

                            "shift+ctrl+k=scroll_page_lines:-1"
                            "shift+ctrl+j=scroll_page_lines:1"
                            "shift+ctrl+u=scroll_page_fractional:-0.5"
                            "shift+ctrl+d=scroll_page_fractional:0.5"
                            "shift+ctrl+p=jump_to_prompt:-1"
                            "shift+ctrl+n=jump_to_prompt:1"
                        ]
                    ];
                };
            };
        };
}
