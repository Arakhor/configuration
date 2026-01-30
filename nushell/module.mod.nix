{
    universal =
        {
            lib,
            pkgs,
            config,
            ...
        }:

        let
            inherit (lib.nushell) isNushellInline mkNushellInline toNushell;
            cfg = config.programs.nushell;

            validatedConfig =
                file:
                pkgs.runCommand "validated-user-config.nu"
                    {
                        nativeBuildInputs = [ cfg.package ];
                    }
                    ''
                        # Run validation
                        output=$(nu -c "try { source ${lib.escapeShellArg file} } catch {|error| \$error.rendered }")

                        # Check for errors
                        if [ -n "$output" ]; then
                          echo "Nushell config validation failed for ${lib.escapeShellArg file}:"
                          echo "$output"
                          exit 1
                        fi

                        # If valid, copy file to output
                        cp ${lib.escapeShellArg file} $out
                    '';

            mkAliases = aliases: lib.concatLines (lib.mapAttrsToList (k: v: "alias ${k} = ${v}") aliases);

            mkSettings =
                settings:
                let
                    flattenSettings =
                        let
                            joinDot = a: b: "${if a == "" then "" else "${a}."}${b}";
                            unravel =
                                prefix: value:
                                if lib.isAttrs value && !isNushellInline value then
                                    lib.concatMap (key: unravel (joinDot prefix key) value.${key}) (builtins.attrNames value)
                                else
                                    [ (lib.nameValuePair prefix value) ];
                        in
                        unravel "";
                    mkLine =
                        { name, value }:
                        ''
                            $env.config.${name} = ${toNushell { } value}
                        '';
                in
                lib.concatMapStrings mkLine (flattenSettings cfg.settings);
        in
        {
            options.programs.nushell = {
                enable = lib.mkEnableOption "nushell";
                package = lib.mkPackageOption pkgs "nushell" { };

                initConfig = lib.mkOption {
                    type = lib.types.lines;
                    description = "Nushell code to be called before settings and aliases are loaded.";
                    default = "";
                };

                settings = lib.mkOption {
                    type = lib.types.attrsOf lib.nushellValue;
                    default = { };
                    example = {
                        show_banner = false;
                        history.format = "sqlite";
                    };
                    description = ''
                        Nushell settings. These will be flattened and assigned one by one to `$env.config` to avoid overwriting the default or existing options.

                        For example:
                        ```nix
                        {
                          show_banner = false;
                          completions.external = {
                            enable = true;
                            max_results = 200;
                          };
                        }
                        ```
                        becomes:
                        ```nushell
                        $env.config.completions.external.enable = true
                        $env.config.completions.external.max_results = 200
                        $env.config.show_banner = false
                        ```
                    '';
                };

                extraConfig = lib.mkOption {
                    type = lib.types.lines;
                    description = "Nushell code to be called after settings and aliases are loaded.";
                    default = "";
                };

                shellAliases = lib.mkOption {
                    type = lib.types.attrsOf lib.types.anything;
                    description = "A set of aliases for nushell.";
                    default = { };
                };

                environmentVariables = lib.mkOption {
                    type = lib.types.attrsOf lib.nushellValue;
                    default = { };
                    example = lib.literalExpression ''
                        {
                          FOO = "BAR";
                          LIST_VALUE = [ "foo" "bar" ];
                          PROMPT_COMMAND = config.lib.nushell.mkNushellInline '''{|| "> "}''';
                          ENV_CONVERSIONS.PATH = {
                            from_string = lib.nushell.mkNushellInline "{|s| $s | split row (char esep) }";
                            to_string = lib.nushell.mkNushellInline "{|v| $v | str join (char esep) }";
                          };
                        }
                    '';
                    description = ''
                        Environment variables to be set.

                        Inline values can be set with `lib.hm.nushell.mkNushellInline`.
                    '';
                };

                plugins = lib.mkOption {
                    type = lib.types.listOf lib.types.package;
                    description = "A list of plugin packages to be installed and added to the nushell plugin registry.";
                    default = [ ];
                };

                libraries = lib.mkOption {
                    type = lib.types.listOf lib.types.path;
                    description = "A list of libraries to be installed and added to the nushell lib list.";
                    default = [ ];
                };

                experimentalOptions = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    description = "Experimental options to enable";
                    default = [ ];
                };

                # We wrap the executable to pass some arguments
                finalPackage = lib.mkOption {
                    type = lib.types.package;
                    readOnly = true;
                    description = "Resulting package.";
                    default = config.wrappers.nushell.wrapped;
                };
            };

            config = lib.mkIf cfg.enable {
                wrappers.nushell = {
                    basePackage = cfg.package;
                    pathAdd = cfg.plugins;
                    env.NU_EXPERIMENTAL_OPTIONS.value = (lib.concatStringsSep "," cfg.experimentalOptions);
                    prependFlags =
                        let
                            hasEnvVars = cfg.environmentVariables != { };
                            envVarsStr = ''
                                load-env ${toNushell { } cfg.environmentVariables}
                            '';
                        in
                        [
                            "--config"
                            (validatedConfig (
                                pkgs.writeText "config.nu" # nu
                                    ''
                                        # Load libraries first
                                        const NU_LIB_DIRS = $NU_LIB_DIRS ++ [ ${lib.concatStringsSep " " cfg.libraries} ];

                                        # Source Nixos Environment
                                        if ("__NIXOS_SET_ENVIRONMENT_DONE" not-in $env) and $nu.is-login {
                                            use ${pkgs.nu_scripts}/share/nu_scripts/modules/capture-foreign-env
                                            open ${config.system.build.setEnvironment}
                                            | capture-foreign-env
                                            | load-env
                                        } 
                                        ${lib.optionalString hasEnvVars envVarsStr}
                                        ${lib.optionalString (cfg.initConfig != "") cfg.initConfig}
                                        ${lib.optionalString (cfg.settings != { }) (mkSettings cfg.settings)}
                                        ${lib.optionalString (cfg.shellAliases != { }) (mkAliases cfg.shellAliases)}
                                        ${lib.optionalString (cfg.extraConfig != "") cfg.extraConfig}
                                    ''
                            ))
                            "--plugin-config"
                            (
                                let
                                    pluginExprs = map (plugin: "plugin add ${lib.getExe plugin}") cfg.plugins;
                                in
                                pkgs.runCommandLocal "plugin.msgpackz" { nativeBuildInputs = [ cfg.package ]; } ''
                                    touch $out {config,env}.nu
                                    nu --config config.nu \
                                    --env-config env.nu \
                                    --plugin-config plugin.msgpackz \
                                    --no-history \
                                    --no-std-lib \
                                    --commands '${lib.concatStringsSep ";" pluginExprs};'
                                    cp plugin.msgpackz $out
                                ''
                            )
                        ];
                };

                lib.nushell = rec {
                    converterBySeparator = char: {
                        from_string = mkNushellInline "{|s| $s | split row '${char}' }";
                        to_string = mkNushellInline "{|v| $v | str join '${char}' }";
                    };
                    esepListConverter = converterBySeparator ":";
                    spaceListConverter = converterBySeparator " ";
                };

                environment = {
                    systemPackages = [ cfg.finalPackage ];
                    pathsToLink = [ "/share/nushell/vendor/autoload" ];
                    shells = [
                        "/run/current-system/sw/bin/nu"
                        (lib.getExe cfg.finalPackage)
                    ];
                };
            };
        };
}
