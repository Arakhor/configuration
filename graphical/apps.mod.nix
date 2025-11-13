inputs: {
    graphical.home =
        { pkgs, lib, ... }:
        {
            packages = with pkgs; [
                foot
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
                blanket
                gnome-clocks
                gnome-calendar
                transmission_4-gtk
                amberol
                nautilus
                mpv
            ];
        };

    graphical.preserveHome.directories = [
        ".config/spotify"
        ".cache/spotify"
    ];
}
