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
        grim
        gsettings-desktop-schemas
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
        transmission_4-gtk
        vesktop
        wayvnc
        wlvncc
        # keep-sorted end
      ];
    };

  graphical.preserveHome.directories = [
    ".config/spotify"
    ".cache/spotify"
  ];
}
