inputs: {
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
        blanket
        gnome-clocks
        gnome-calendar
      ];

      file.xdg_config."alacritty/alacritty.toml".source =
        let
          alacrittyConfig = {
            general.import = [ "colors.toml" ];
            mouse.hide_when_typing = true;
            font = {
              normal.family = "Lilex";
              size = 12;
            };
            scrolling.history = 10000;
            window = {
              padding = {
                x = 6;
                y = 6;
              };
              dynamic_padding = true;
              decorations = "None";
              opacity = 0.8;
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
