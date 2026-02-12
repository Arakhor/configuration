{
    graphical =
        {
            pkgs,
            lib,
            config,
            ...
        }:
        {
            environment.systemPackages = [
                pkgs.swayimg
                pkgs.gthumb
            ];

            maid-users.file.xdg_config."swayimg/config".source = (pkgs.formats.toml { }).generate "config" {
                general.compositor = false;
                font.name = config.style.fonts.sansSerif.name;

                "keys.viewer" = {
                    Left = "prev_file";
                    Right = "next_file";
                    f = "fullscreen";
                    plus = "zoom +10";
                    underscore = "zoom -10";
                    ScrollUp = "zoom +5";
                    ScrollDown = "zoom -5";
                    r = "zoom optimal";
                    less = "rotate_left";
                    greater = "rotate_right";
                    x = "flip_vertical";
                    z = "flip_horizontal";
                    "Ctrl+r" = "reload";
                    i = "info viewer";
                    q = "exit";
                    question = "help";
                };
            };

        };
}
