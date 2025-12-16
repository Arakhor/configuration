{
  graphical =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = [ pkgs.alacritty ];
      home.file.xdg_config."alacritty/alacritty.toml".source =
        let
          alacrittyConfig = {
            mouse.hide_when_typing = true;
            font = {
              normal.family = config.fonts.monospace;
              size = 12;
            };
            scrolling.history = 10000;
            general.import = [ "dank-theme.toml" ];
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
          };
        in
        ((pkgs.formats.toml { }).generate "alacritty.toml" alacrittyConfig);
    };
}
