{ zen-browser, ... }:
{
    graphical =
        { pkgs, ... }:
        {
            environment.systemPackages = with pkgs; [
                # keep-sorted start
                amberol
                appimage-run
                baobab
                blanket
                brightnessctl
                caligula
                cheese
                eog
                gnome-calendar
                gnome-characters
                gnome-clocks
                gnome-disk-utility
                gnome-photos
                grim
                gsettings-desktop-schemas
                libreoffice-fresh
                mpv
                nautilus
                obsidian
                pairdrop
                playerctl
                rnote
                seahorse
                slurp
                stackblur-go
                subversion
                swayimg
                thunderbird
                transmission_4-gtk
                vesktop
                wayvnc
                wlvncc
                zathura
                zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.twilight
                # keep-sorted end
            ];
        };
}
