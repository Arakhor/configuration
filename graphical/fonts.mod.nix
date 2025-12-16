let
  settings = {
    sans = "Lexend";
    serif = "Noto Serif";
    monospace = "Monaspace Neon";
    emoji = "Noto Color Emoji";
  };
in
{
  graphical =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.fonts = lib.mapAttrs (lib.const (
        value:
        lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = value;
        }
      )) settings;

      config = {

        nixpkgs.overlays = [
          (prev: final: {
            monaspace = prev.stdenvNoCC.mkDerivation (finalAttrs: {
              pname = "monaspace";
              version = "1.301";

              src = prev.fetchFromGitHub {
                owner = "githubnext";
                repo = "monaspace";
                tag = "v${finalAttrs.version}";
                hash = "sha256-8tPwm92ZtaXL9qeDL+ay9PdXLUBBsspdk7/0U8VO0Tg=";
              };

              outputs = [
                "out"
                "otf"
                "ttf"
                "woff"
                "woff2"
                "nerdfonts"
              ];

              installPhase = ''
                runHook preInstall

                for family in Argon Krypton Neon Radon Xenon; do
                  echo 'Installing frozen fonts...'
                  install -Dm444 'fonts/Frozen Fonts/Monaspace '"$family"/Monaspace"$family"Frozen-*.ttf -t "$ttf"/share/fonts/truetype/'Monaspace '"$family"' Frozen'
                  echo 'Installing nerd fonts...'
                  install -Dm444 'fonts/NerdFonts/Monaspace '"$family"/Monaspace"$family"NF-*.otf -t "$nerdfonts"/share/fonts/opentype/'Monaspace '"$family"' NF'
                  echo 'Installing static fonts...'
                  install -Dm444 'fonts/Static Fonts/Monaspace '"$family"/Monaspace"$family"-*.otf -t "$otf"/share/fonts/opentype/'Monaspace '"$family"
                  echo 'Installing variable fonts...'
                  install -Dm444 'fonts/Variable Fonts/Monaspace '"$family"/'Monaspace '"$family"' Var'.ttf -t "$ttf"/share/fonts/truetype

                  echo 'Installing static web fonts (woff)...'
                  install -Dm444 'fonts/Web Fonts/Static Web Fonts/Monaspace '"$family"/Monaspace"$family"-*.woff -t "$woff"/share/fonts/woff/'Monaspace '"$family"
                  echo 'Installing static web fonts (woff2)...'
                  install -Dm444 'fonts/Web Fonts/Static Web Fonts/Monaspace '"$family"/Monaspace"$family"-*.woff2 -t "$woff2"/share/fonts/woff2/'Monaspace '"$family"

                  echo 'Installing variable web fonts (woff)...'
                  install -Dm444 'fonts/Web Fonts/Variable Web Fonts/Monaspace '"$family"/'Monaspace '"$family"' Var'.woff -t "$woff"/share/fonts/woff
                  echo 'Installing variable web fonts (woff2)...'
                  install -Dm444 'fonts/Web Fonts/Variable Web Fonts/Monaspace '"$family"/'Monaspace '"$family"' Var'.woff2 -t "$woff2"/share/fonts/woff2
                done

                mkdir -p "$out"/share/fonts
                ln -s "$otf"/share/fonts/opentype "$out"/share/fonts/opentype
                ln -s "$ttf"/share/fonts/truetype "$out"/share/fonts/truetype
                ln -s "$woff"/share/fonts/woff "$out"/share/fonts/woff
                ln -s "$woff2"/share/fonts/woff2 "$out"/share/fonts/woff2

                runHook postInstall
              '';
            });

          })
        ];

        environment.variables = {
          QT_NO_SYNTHESIZED_BOLD = "1";
          FREETYPE_PROPERTIES = lib.concatStringsSep " " [
            "autofitter:no-stem-darkening=0"
            "autofitter:darkening-parameters=500,0,1000,500,2500,500,4000,0"
            "cff:no-stem-darkening=0"
            "type1:no-stem-darkening=0"
            "t1cid:no-stem-darkening=0"
          ];
        };

        preserveHome.directories = [ ".cache/fontconfig" ];

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
            cascadia-code
            nebula-sans
            julia-mono
            monaspace

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
                serif = [ config.fonts.serif ];
                sansSerif = [ config.fonts.sans ];
                monospace = [ config.fonts.monospace ];
                emoji = [ config.fonts.emoji ];
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
    };
}
