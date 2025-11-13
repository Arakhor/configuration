inputs: {
  universal.home =
    { pkgs, ... }:
    {
      packages = with pkgs; [
        ripgrep
        fd
        gh
        git
        bat
        fzf
        zoxide
        bottom
        fastfetch
        socat
        pastel
        moor
        eza
        jq
        just
        dust
        moreutils
        trash-cli
        vivid
      ];
      file.home.".gitconfig".text = ''
        [credential "https://github.com"]
        	helper = 
        	helper = !/etc/profiles/per-user/arakhor/bin/gh auth git-credential
        [credential "https://gist.github.com"]
        	helper = 
        	helper = !/etc/profiles/per-user/arakhor/bin/gh auth git-credential
        [user]
        	name = arakhor
        	email = arakhor@pm.me
      '';

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
