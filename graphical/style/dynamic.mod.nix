{ wallpapers, ... }:
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
            tomlFormat = pkgs.formats.toml { };

            custom_colors = {
                success = "#4caf50";
                warning = "#ffeb3b";
            };
        in
        {
            options.style.dynamic = {
                scheme = lib.mkOption {
                    description = "Color scheme type for dynamic theming with matugen";
                    type = lib.types.enum [
                        "content"
                        "expressive"
                        "fidelity"
                        "fruit-salad"
                        "monochrome"
                        "neutral"
                        "rainbow"
                        "tonal-spot"
                        "vibrant"
                    ];
                    default = "tonal-spot";
                    apply = v: "scheme-" + v;
                };

                # wallpapers = {
                #     description = "Collection of wallpapers used for dynamic theming with matugen";
                #     type = with lib.types; either path (listOf path);
                #     example = [
                #         /home/user/wallpapers/mountain.jpg
                #         /home/user/wallpapers/ocean.jpg
                #     ];
                #     default = [ ];
                # };

                wallpapersDir = lib.mkOption {
                    default = "${wallpapers}/images";
                    type = lib.types.path;
                };

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
                                    type = lib.types.nullOr lib.types.lines;
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
            };

            config = {
                lib.style.genMatugenKeys =
                    {
                        scheme ? "default",
                        format ? "hex",
                    }:
                    lib.genAttrs (
                        pkgs.runCommandLocal "matugen-keys"
                            {
                                nativeBuildInputs = [ pkgs.matugen ];
                            }
                            (
                                pkgs.writers.writeNu "matugen-keys" # nu
                                    ''
                                        matugen color hex "#ffffff" --config ${
                                            tomlFormat.generate "matugen-config-custom-colors-only" {
                                                config = { inherit custom_colors; };
                                                templates = { };
                                            }
                                        } --dry-run --json hex
                                        | from json
                                        | get colors
                                        | columns
                                        | to json
                                        | save $env.out
                                    ''
                            )
                        |> builtins.readFile
                        |> builtins.fromJSON
                    ) (name: "{{colors.${name}.${scheme}.${format}}}")
                    // {
                        mode = "{{mode}}";
                        image = "{{image}}";
                    };

                maid-users.file.xdg_config."matugen/config.toml".source = tomlFormat.generate "matugen-config" {
                    config = {
                        caching = true;
                        inherit custom_colors;
                    };
                    templates = lib.mapAttrs (n: v: {
                        output_path = "~/" + v.target;
                        input_path = if v.text != null then pkgs.writeText n v.text else v.source;
                        pre_hook = v.hooks.before;
                        post_hook = v.hooks.after;
                    }) cfg.templates;
                };

                environment.systemPackages = [
                    pkgs.matugen
                ];

                preserveHome = {
                    files = lib.mapAttrsToList (_: v: v.target) cfg.templates;
                    directories = [ ".cache/matugen" ];
                };

                maid-users.file.home."pictures/wallpapers".source = "${wallpapers}/images";
            };
        };
}
