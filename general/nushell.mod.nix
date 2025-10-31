{ nushell-nightly, ... }:
{
    universal =
        { lib, pkgs, ... }:
        let
            nu_scripts = "${pkgs.nu_scripts}/share/nu_scripts";
        in
        {
            programs.bash.interactiveShellInit = ''
                if ! [ "$TERM" = "dumb" ]; then
                  exec nu
                fi
            '';

            environment = {
                systemPackages = [ pkgs.nushell ];
                pathsToLink = [
                    "/share/fish/vendor_completions.d"
                    "/share/nushell/vendor/autoload"
                ];
            };

            home =
                { config, ... }:
                let
                    cfg = config.programs.nushell;
                in
                {
                    options.programs.nushell = {
                        extraConfig = lib.mkOption {
                            type = lib.types.lines;
                            description = "Extra configuration to be written to config.nu";
                            default = "";
                        };
                        aliases = lib.mkOption {
                            type = lib.types.attrsOf lib.types.anything;
                            description = "A set of aliases for nushell.";
                            default = { };
                        };
                        variables = lib.mkOption {
                            type = lib.types.attrsOf lib.types.anything;
                            description = "A set of environment variables to load in nushell.";
                            default = { };
                        };
                        plugins = lib.mkOption {
                            type = lib.types.listOf lib.types.package;
                            description = "A list of plugin packages to be installed and added to the nushell plugin registry.";
                            default = [ ];
                        };
                    };
                    config = {
                        packages = with pkgs; [
                            fish
                            zoxide
                            starship
                        ];
                        programs.nushell = {
                            variables = {
                                CARAPACE_BRIDGES = "fish,bash";
                                CARAPACE_LENIENT = "1";
                            };
                            plugins = with pkgs.nushellPlugins; [
                                formats
                                gstat
                                query
                                polars
                            ];
                            aliases = {
                                fg = "job unfreeze";
                            };
                        };
                        file.xdg_config."nushell/config.nu".text = # nu
                            ''
                                load-env {${lib.concatStringsSep ", " (lib.mapAttrsToList (n: v: "${n}: \"${v}\"") cfg.variables)}}

                                const NU_LIB_DIRS = $NU_LIB_DIRS ++ [
                                  ${nu_scripts}/nu-hooks
                                  ${nu_scripts}/themes
                                ];

                                # Parse text as nix expression
                                def "from nix" []: string -> any {
                                    ${lib.getExe pkgs.lix} eval --json -f - | from json
                                }

                                # Convert table data into a nix expression
                                def "to nix" [
                                    --format(-f) # Format the result
                                ]: any -> string {
                                    to json --raw
                                    | str replace --all "''$" $"(char single_quote)(char single_quote)$"
                                    | nix eval --expr $"builtins.fromJSON '''($in)'''"
                                    | if $format { ${lib.getExe pkgs.nixfmt-rfc-style} - | ${lib.getExe pkgs.bat} --paging=never --style=plain -l nix } else { $in }
                                }

                                source /home/arakhor/configuration/nushell/config.nu
                                ${cfg.extraConfig}
                                ${lib.concatStringsSep "\n " (lib.mapAttrsToList (n: v: "alias ${n} = ${v}") cfg.aliases)}
                            '';
                        file.xdg_config."nushell/plugin.msgpackz" = lib.mkIf (cfg.plugins != [ ]) {
                            source =
                                let
                                    msgPackz = pkgs.runCommand "nuPlugin-msgPackz" { } ''
                                        mkdir -p "$out"
                                        ${lib.getExe pkgs.nushell} \
                                          --plugin-config "$out/plugin.msgpackz" \
                                          --commands '${
                                              lib.concatStringsSep "\n" (map (plugin: "plugin add ${lib.getExe plugin}") cfg.plugins)
                                          }'
                                    '';
                                in
                                "${msgPackz}/plugin.msgpackz";
                        };
                    };

                };

            preserveHome = {
                files = [
                    ".config/nushell/history.sqlite3"
                    ".config/nushell/history.sqlite3-shm"
                    ".config/nushell/history.sqlite3-wal"
                ];
                directories = [
                    ".cache/nushell"
                    ".local/share/nushell"
                ];
            };

            nixpkgs.overlays = [ nushell-nightly.overlays.default ];
            nix.settings.substituters = [ "https://nushell-nightly.cachix.org" ];
            nix.settings.trusted-public-keys = [
                "nushell-nightly.cachix.org-1:nLwXJzwwVmQ+fLKD6aH6rWDoTC73ry1ahMX9lU87nrc="
            ];
        };
}
