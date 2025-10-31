inputs: {
    universal.home =
        { pkgs, ... }:
        {
            packages = with pkgs; [
                ripgrep
                fd
                yazi
                gh
                git
                eza
                bat
                fzf
                zoxide
                carapace
                bottom
                fastfetch
                socat
                pastel
                moor
                jq
                just
                dust
                moreutils
            ];
            programs.nushell.variables = {
                PAGER = "moor";
                SYSTEMD_PAGER = "moor";
                SYSTEMD_PAGERSECURE = "moor";
            };
        };

    universal.preserveHome.directories = [
        ".cache/starship"
        ".local/share/zoxide"
        ".local/state/yazi"
    ];

    personal.home =
        { pkgs, lib, ... }:
        {
            packages = with pkgs; [
                foot
                alacritty
                ghostty
                firefox
                spotify
                appimage-run
                seahorse
                caligula
                vesktop
                grim
                slurp
                gsettings-desktop-schemas
                playerctl
                brightnessctl
                pairdrop
                swayimg
                stackblur-go
                subversion
                wayvnc
                wlvncc
                rnote
                obsidian
                beeper
            ];

            dconf.settings."/org/gnome/desktop/wm/preferences" = {
                button-layout = "appmenu:close";
            };

            file.xdg_config."alacritty/alacritty.toml".source =
                let
                    alacrittyConfig = {
                        mouse.hide_when_typing = true;
                        font = {
                            normal.family = "Aporetic Serif Mono";
                            size = 18;
                        };
                        scrolling.history = 10000;
                        window = {
                            padding = {
                                x = 6;
                                y = 6;
                            };
                            dynamic_padding = true;
                            decorations = "None";
                            opacity = 0.7;
                            dynamic_title = true;
                        };
                        colors = {
                            transparent_background_colors = true;
                            draw_bold_text_with_bright_colors = true;
                            primary.background = "#000000";
                        };
                    };
                in
                ((pkgs.formats.toml { }).generate "alacritty.toml" alacrittyConfig);
        };

    personal.preserveHome.directories = [
        ".mozilla/firefox"
        ".config/spotify"
        ".cache/spotify"
    ];
}
