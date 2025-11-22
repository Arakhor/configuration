{
  graphical.home =
    { pkgs, lib, ... }:
    {
      packages = [ pkgs.alacritty-graphics ];
      file.xdg_config."alacritty/alacritty.toml".source =
        let
          alacrittyConfig = {
            mouse.hide_when_typing = true;
            font = {
              normal.family = "Aporetic Sans";
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
              bright = {
                black = "#414868";
                blue = "#8db0ff";
                cyan = "#a4daff";
                green = "#9fe044";
                magenta = "#c7a9ff";
                red = "#ff899d";
                white = "#c0caf5";
                yellow = "#faba4a";
              };
              normal = {
                black = "#15161e";
                blue = "#7aa2f7";
                cyan = "#7dcfff";
                green = "#9ece6a";
                magenta = "#bb9af7";
                red = "#f7768e";
                white = "#a9b1d6";
                yellow = "#e0af68";
              };
              primary = {
                background = "#000000";
                foreground = "#c0caf5";
              };
            };
          };
        in
        ((pkgs.formats.toml { }).generate "alacritty.toml" alacrittyConfig);
    };
}
