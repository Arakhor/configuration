{
    universal =
        {
            pkgs,
            lib,
            ...
        }:
        {
            environment.pathsToLink = [
                "/share/zsh"
                "/share/fish"
            ];

            wrappers.carapace = {
                basePackage = pkgs.carapace;
                pathAdd = with pkgs; [
                    zsh
                    fish
                    bash
                ];
                env =
                    lib.mapAttrs
                        (_: value: {
                            value = toString value;
                            force = false;
                        })
                        {
                            CARAPACE_BRIDGES = "zsh,fish,bash";
                            CARAPACE_HIDDEN = 1;
                            CARAPACE_LENIENT = 1;
                            CARAPACE_MATCH = 1; # 0 = case sensitive, 1 = case insensitive
                            CARAPACE_ENV = 0; # disable get-env, del-env and set-env commands
                        };

            };

            programs.nushell = {
                initConfig = # nu
                    ''
                        let carapace_completer = {|spans: list<string>| 
                          load-env {
                            CARAPACE_SHELL_BUILTINS: (help commands | where category != "" | get name | each { split row " " | first } | uniq | str join "\n")
                            CARAPACE_SHELL_FUNCTIONS: (help commands | where category == "" | get name | each { split row " " | first } | uniq | str join "\n")
                          }

                          # if the current command is an alias, get it's expansion
                          let expanded_alias = (scope aliases | where name == $spans.0 | $in.0?.expansion?)

                          # overwrite
                          let spans = (if $expanded_alias != null  {
                            # put the first word of the expanded alias first in the span
                            $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
                          } else {
                            $spans | skip 1 | prepend ($spans.0)
                          })

                          carapace $spans.0 nushell ...$spans
                          | from json
                          | if ($in | default [] | where value =~ $"($spans | last)ERR_?" | is-empty) { $in } else { null }
                          | default --empty null
                        }
                    '';

                extraConfig = # nu
                    ''
                        # def nix-completer [spans: list<string>] {
                        #   let current_arg = $spans | length | $in - 1
                        #   with-env {NIX_GET_COMPLETIONS: $current_arg} { $spans | skip 1 | ^nix ...$in }
                        #   | lines
                        #   | skip 1
                        #   | parse "{value}\t{description}"
                        # }

                        # @complete nix-completer
                        # extern nix []

                        def sudo-completer [spans: list<string>] {
                          do $env.config.completions.external.completer ($spans | skip 1)
                        }

                        @complete sudo-completer
                        extern sudo []
                    '';

                settings.completions = {
                    case_sensitive = false;
                    quick = true;
                    partial = true;
                    algorithm = "prefix";
                    external.completer = lib.mkNushellInline "$carapace_completer";
                };
            };
        };
}
