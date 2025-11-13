{
    graphical =
        { pkgs, ... }:
        {
            environment.variables = {
                QT_NO_SYNTHESIZED_BOLD = "1";
                FREETYPE_PROPERTIES = "autofitter:no-stem-darkening=0 autofitter:darkening-parameters=500,0,1000,500,2500,500,4000,0 cff:no-stem-darkening=0 type1:no-stem-darkening=0 t1cid:no-stem-darkening=0";
            };

            environment.systemPackages = [ pkgs.font-manager ];

            fonts = {
                packages = with pkgs; [
                    # icon fonts
                    material-symbols

                    # normal fonts
                    noto-fonts
                    inter
                    lexend
                    aporetic
                    ibm-plex
                    lilex
                    monaspace
                    cascadia-code
                    nebula-sans
                    julia-mono

                    # nerdfonts
                    nerd-fonts.symbols-only
                ];

                fontconfig = {
                    enable = true;
                    defaultFonts =
                        let
                            addAll = builtins.mapAttrs (
                                _: v:
                                v
                                ++ [
                                    "Symbols Nerd Font"
                                    "Noto Sans Symbols"
                                    "Noto Sans Symbols 2"
                                    "Noto Color Emoji"
                                ]
                            );
                        in
                        addAll {
                            serif = [ "IBM Plex Serif" ];
                            sansSerif = [ "Lexend" ];
                            monospace = [ "Cascadia Code" ];
                            emoji = [ "Noto Color Emoji" ];
                        };
                    localConf = # xml
                        ''
                            <?xml version="1.0"?>
                            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
                            <fontconfig>
                              <description>Barely compatible stem-darkening extension, providing the correct emboldening to small glyphs</description>
                              <match target="font">
                                <test name="pixelsize" compare="less">
                                  <double>14.0</double>
                                </test>
                                <edit name="embolden" mode="assign">
                                  <bool>true</bool>
                                </edit>
                              </match>
                            </fontconfig>
                        '';
                };
                fontDir = {
                    enable = true;
                    decompressFonts = true;
                };
            };
        };
}
