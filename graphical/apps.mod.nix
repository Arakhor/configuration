inputs: {
  graphical.home =
    { pkgs, ... }:
    {
      packages = with pkgs; [
        # keep-sorted start
        amberol
        appimage-run
        blanket
        brightnessctl
        caligula
        foot

        gnome-calendar
        gnome-clocks
        gnome-photos
        gnome-characters
        gnome-disk-utility
        eog
        cheese
        baobab

        grim
        gsettings-desktop-schemas
        kdePackages.dolphin
        libreoffice-fresh
        mpv
        nautilus
        obsidian
        pairdrop
        playerctl
        rnote
        seahorse
        slurp
        spotify
        stackblur-go
        subversion
        swayimg
        thunderbird
        transmission_4-gtk
        vesktop
        wayvnc
        wlvncc
        zathura
        # keep-sorted end
      ];
    };

  graphical.preserveHome.directories = [
    ".config/spotify"
    ".cache/spotify"
  ];
}
