# GREAT START, MOST OF THE FUNCTIONALITY IS ALREADY DONE
#
# TODO: Schemes should adjust to wallpapers (automatically with optional manual override)
# TODO: https://github.com/Neurarian/image-hct
# TODO: Finish darkman service and integrate with this
#
{ matugen, image-hct, ... }:
{
    graphical =
        {
            pkgs,
            lib,
            config,
            ...
        }:
        let
            cfg = config.style.dynamic;
            wallCfg = config.style.wallpaper;

            tomlFormat = pkgs.formats.toml { };

            custom_colors = {
                success = "#4caf50";
                warning = "#ffeb3b";
            };

            buildTheme =
                wall:
                pkgs.runNuCommand "matugen-theme-${baseNameOf wall}" { }
                    #nu
                    ''
                        const WALL = "${wall}"

                        let props = {
                           ${
                               map (prop: "${prop}: (${pkgs.image-hct}/bin/image-hct '${wall}' ${prop})") [
                                   "hue"
                                   "chroma"
                                   "tone"
                               ]
                               |> lib.concatLines
                           } 
                        }

                        let scheme = match ($props.chroma | into int) {
                            $p if $p > 75 => { 'scheme-rainbow' }
                            $p if $p < 25 => { 'scheme-neutral' }
                            _ => { 'scheme-tonal-spot' }
                        }

                        mkdir $env.out

                        cp ${matugenConfig} ($env.out)/config.toml
                        (
                            ${pkgs.matugen}/bin/matugen image $WALL
                            --config ($env.out)/config.toml
                            --type $scheme
                            --source-color-index 0
                            --base16-backend 'wal'
                        )
                        rm ($env.out)/config.toml
                    '';

            matugenConfig = tomlFormat.generate "config.toml" {
                config = {
                    caching = false;
                    inherit custom_colors;
                };
                templates = lib.mapAttrs (n: v: {
                    output_path = v.target;
                    input_path = if v.text != null then pkgs.writeText n v.text else v.source;
                }) cfg.templates;
            };
        in
        {
            options.style.dynamic = {
                enable = lib.mkEnableOption "Matugen declarative theming" // {
                    default = cfg.templates != { };
                };

                # scheme = lib.mkOption {
                #     description = "Color scheme type for dynamic theming with matugen";
                #     type = lib.types.enum [
                #         "content"
                #         "expressive"
                #         "fidelity"
                #         "fruit-salad"
                #         "monochrome"
                #         "neutral"
                #         "rainbow"
                #         "tonal-spot"
                #         "vibrant"
                #     ];
                #     default = "tonal-spot";
                #     apply = v: "scheme-" + v;
                # };

                templates = lib.mkOption {
                    type =
                        with lib.types;
                        attrsOf (submodule {
                            options = {
                                source = lib.mkOption {
                                    type = types.coercedTo types.path (p: "${p}") types.str;
                                    description = "Path to the template";
                                    example = "./style.css";
                                };
                                text = lib.mkOption {
                                    default = null;
                                    type = nullOr lines;
                                    description = "Text to write to the resulting file, as an alternative to `.source`.";
                                };
                                target = lib.mkOption {
                                    type = str;
                                    description = "Path where the generated file will be written to, relative to home directory";
                                    example = ".config/style.css";
                                };
                                hooks = {
                                    before = lib.mkOption {
                                        type = str;
                                        default = "";
                                        description = "Runs before the template is exported. You can use keywords here.";
                                        example = "echo source color {{colors.source_color.default.hex}}, source image {{image}}";
                                    };
                                    after = lib.mkOption {
                                        type = str;
                                        default = "";
                                        description = "Runs after the template is exported. You can use keywords here.";
                                        example = "echo after gen {{colors.primary.default.rgb}}";
                                    };
                                };
                            };
                        });
                    default = { };
                    description = ''
                        Templates that have `@{placeholders}` which will be replaced by the respective colors.
                        See <https://github.com/InioX/matugen/wiki/Configuration#example-of-all-the-color-keywords> for a list of colors.
                    '';
                };

                themeBundle = lib.mkOption {
                    type = lib.types.package;
                    readOnly = true;
                    default =
                        let
                            themeEntries = map (wall: {
                                name = lib.strings.unsafeDiscardStringContext (baseNameOf wall);
                                path = buildTheme wall;
                            }) wallCfg.randomise.wallpapers;
                        in
                        pkgs.linkFarm "dynamic-themes-bundle" themeEntries;
                    description = "Generated theme files from random wallpaper pool.";
                };
            };

            config = lib.mkIf cfg.enable {
                nixpkgs.overlays = lib.singleton (
                    final: prev: {
                        matugen = matugen.packages.${final.stdenv.hostPlatform.system}.default;
                        image-hct = image-hct.packages.${final.stdenv.hostPlatform.system}.default;
                    }
                );

                environment.systemPackages = [
                    pkgs.matugen
                    pkgs.image-hct
                ]; # NOTE: testing purposes only

                # Templates point to paths relative to home directory
                maid-users.file.home =
                    let
                        collected = lib.mapAttrsToList (_: v: v.target) cfg.templates;
                    in
                    lib.genAttrs collected (path: {
                        source = "{{xdg_cache_home}}/theme/${path}";
                    });

                maid-users.file.xdg_cache."theme" = lib.mkIf (!wallCfg.randomise.enable) {
                    source = buildTheme wallCfg.default;
                };

                # maid-users.systemd.services.set-theme = {
                #     description = "Set the desktop theme";
                #     wants = [ "set-wallpaper.service" ];
                #     before = [ "set-wallpaper.service" ];

                #     unitConfig.X-SwitchMethod = "keep-old";

                #     serviceConfig = {
                #         Type = "oneshot";
                #         ExecStart = (lib.getExe setTheme);
                #     };
                # };

                # Generate helper functions for use in templates
                # Default + config defined colors, skipping full palettes
                # since they're generated for builtin colors only and
                # I have no use for them anyway.
                lib.style.genMatugenKeys =
                    {
                        scheme ? "default",
                        format ? "hex",
                    }:
                    let
                        pixel = pkgs.runCommand "pixel.png" {
                            color = "#cbacde";
                        } "${lib.getExe' pkgs.imagemagick "convert"} xc:$color png32:$out";

                        generated =
                            pkgs.runNuCommandLocal "matugen-keys"
                                {
                                    nativeBuildInputs = [ pkgs.matugen ];
                                }
                                # nu
                                ''
                                    let x = (
                                        matugen image ${pixel}
                                        --source-color-index 0
                                        --config ${
                                            tomlFormat.generate "matugen-config-custom-colors-only" {
                                                config = { inherit custom_colors; };
                                                templates = { };
                                            }
                                        }
                                        --fallback-color "#cbacde"
                                        --dry-run
                                        --json hex
                                        --base16-backend 'wal'
                                    )
                                    | from json

                                    {
                                        colors: ($x.colors | columns)
                                        base16: ($x.base16 | columns)
                                        other: ($x | reject palettes colors base16 | columns) 
                                    }
                                    | to json
                                    | save $env.out
                                ''
                            |> builtins.readFile
                            |> builtins.fromJSON;
                    in
                    (lib.genAttrs generated.colors (name: "{{colors.${name}.${scheme}.${format}}}"))
                    // (lib.genAttrs generated.base16 (name: "{{base16.${name}.${scheme}.${format}}}"))
                    // (lib.genAttrs generated.other (name: "{{${name}}}"));

                # Preserve active theme
                # preserveHome = {
                #     directories = [ ".active-theme" ];
                # };
            };
        };
}
