{
  universal =
    {
      lib,
      pkgs,
      nixosConfig,
      homeConfig,
      ...
    }:

    let
      inherit (lib.ns.nushell) isNushellInline mkNushellInline toNushell;
      cfg = nixosConfig.programs.nushell;

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

      preInitNu = pkgs.writeText "preinit.nu" ''
        # Source Nixos Environment
        if ("__NIXOS_SET_ENVIRONMENT_DONE" not-in $env) and $nu.is-login {
            use ${pkgs.nu_scripts}/share/nu_scripts/modules/capture-foreign-env
            open ${nixosConfig.system.build.setEnvironment}
            | capture-foreign-env
            | load-env
        } 
      '';

      initNu = # nu
        pkgs.writeText "init.nu" ''
          ${cfg.shellInit}
        '';

      loginInitNu = # nu
        pkgs.writeText "login.nu" ''
          ${cfg.loginShellInit}
        '';

      interactiveInitNu = # nu
        pkgs.writeText "interactive.nu" ''
          ${cfg.interactiveShellInit}
          ${cfg.promptInit}
          ${mkAliases cfg.shellAliases}
        '';

    in
    {
      options.programs.nushell = {
        enable = lib.mkEnableOption "nushell";
        package = lib.mkPackageOption pkgs "nushell" { };

        settings = lib.mkOption {
          type = lib.types.attrsOf lib.ns.types.nushellValue;
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

        shellInit = lib.mkOption {
          type = lib.types.lines;
          description = "Configuration to be read by every shell";
          default = "";
        };

        promptInit = lib.mkOption {
          type = lib.types.lines;
          description = "Shell script code used to initialise the zsh prompt.";
          default = "";
        };

        interactiveShellInit = lib.mkOption {
          type = lib.types.lines;
          description = "Shell script code called during interactive nushell shell initialisation.";
          default = "";
        };

        loginShellInit = lib.mkOption {
          type = lib.types.lines;
          description = "Shell script code called during zsh login shell initialisation.";
          default = "";
        };

        shellAliases = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          description = "A set of aliases for nushell.";
          default = { };
        };

        environmentVariables = lib.mkOption {
          type = lib.types.attrsOf lib.ns.types.nushellValue;
          default = { };
          example = lib.literalExpression ''
            {
              FOO = "BAR";
              LIST_VALUE = [ "foo" "bar" ];
              PROMPT_COMMAND = nixosConfig.lib.nushell.mkNushellInline '''{|| "> "}''';
              ENV_CONVERSIONS.PATH = {
                from_string = lib.ns.nushell.mkNushellInline "{|s| $s | split row (char esep) }";
                to_string = lib.ns.nushell.mkNushellInline "{|v| $v | str join (char esep) }";
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
          default = pkgs.wrapped.nushell;
        };
      };

      config = lib.mkIf cfg.enable {
        wrappers.nushell = {
          basePackage = cfg.package;
          pathAdd = cfg.plugins;
          env.NU_EXPERIMENTAL_OPTIONS.value = (lib.concatStringsSep "," cfg.experimentalOptions);
          prependFlags = [
            "--config"
            (pkgs.writeText "config.nu" # nu
              ''
                # Load libraries first
                const NU_LIB_DIRS = $NU_LIB_DIRS ++ [ ${lib.concatStringsSep " " cfg.libraries} ];

                source (if ($nu.is-login) {"${preInitNu}"})
                ${
                  let
                    hasEnvVars = cfg.environmentVariables != { };
                    envVarsStr = ''
                      load-env ${toNushell { } cfg.environmentVariables}
                    '';
                  in
                  lib.optionalString hasEnvVars envVarsStr
                }

                source "${initNu}"
                source (if ($nu.is-login) {"${loginInitNu}"})
                source (if ($nu.is-interactive) {"${interactiveInitNu}"})

                ${lib.optionalString (cfg.settings != { }) (mkSettings cfg.settings)}

                # Source user configuration if it exists
                const def_user_config_file = $nu.default-config-dir | path join config.nu
                source (if ($def_user_config_file | path exists) {$def_user_config_file})
              ''
            )
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
          writeNu =
            name: argsOrScript:
            if lib.isAttrs argsOrScript && !lib.isDerivation argsOrScript then
              pkgs.writers.makeScriptWriter (argsOrScript // { interpreter = lib.getExe cfg.finalPackage; }) name
            else
              pkgs.writers.makeScriptWriter { interpreter = lib.getExe cfg.finalPackage; } name argsOrScript;
          writeNuBin = name: writeNu "/bin/${name}";
          converterBySeparator = char: {
            from_string = mkNushellInline "{|s| $s | split row \"${char}\" }";
            to_string = mkNushellInline "{|v| $v | str join \"${char}\" }";
          };
          esepListConverter = converterBySeparator "(char esep)";
          spaceListConverter = converterBySeparator "(char space)";
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
