{
    personal =
        { pkgs, ... }:
        {
            environment.variables = {
                QT_NO_SYNTHESIZED_BOLD = "1";
                FREETYPE_PROPERTIES = "autofitter:no-stem-darkening=0 autofitter:darkening-parameters=500,0,1000,500,2500,500,4000,0 cff:no-stem-darkening=0 type1:no-stem-darkening=0 t1cid:no-stem-darkening=0";
            };

            fonts = {
                packages = with pkgs; [
                    # icon fonts
                    material-symbols

                    # normal fonts
                    inter
                    lexend
                    inter
                    noto-fonts
                    roboto
                    aporetic
                    ibm-plex
                    lilex

                    # nerdfonts
                    nerd-fonts.symbols-only
                ];

                fontconfig = {
                    enable = true;
                    defaultFonts = {
                        serif = [ "IBM Plex Serif" ];
                        sansSerif = [ "IBM Plex Sans" ];
                        monospace = [ "Berkeley Mono Condensed" ];
                        emoji = [ "Noto Color Emoji" ];
                    };
                };
                fontDir = {
                    enable = true;
                    decompressFonts = true;
                };
            };
            preserveHome.directories = [ ".local/share/fonts" ];
        };
}
