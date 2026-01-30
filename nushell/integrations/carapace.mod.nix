{
    universal =
        {
            pkgs,
            lib,
            ...
        }:
        {
            # Enabling those to install completions
            programs.fish.enable = true;
            programs.zsh.enable = true;

            environment.systemPackages = with pkgs; [
                carapace
                carapace-bridge
            ];

            programs.nushell = {
                initConfig = # nu
                    ''
                        path add $"($nu.home-dir)/.config/carapace/bin"

                        load-env {
                            CARAPACE_BRIDGES: 'zsh,fish,bash,inshellisense'
                            CARAPACE_HIDDEN: 2
                            CARAPACE_LENIENT: 1
                            CARAPACE_MATCH: 1 # 0 = case sensitive, 1 = case insensitive
                            CARAPACE_NOSPACE: '*'
                            CARAPACE_MERGEFLAGS: 1
                            CARAPACE_ENV: 0 # disable get-env, del-env and set-env commands
                            CARAPACE_SHELL_BUILTINS: (help commands | where category != "" | get name | each { split row " " | first } | uniq | str join "\n")
                            CARAPACE_SHELL_FUNCTIONS: (help commands | where category == "" | get name | each { split row " " | first } | uniq | str join "\n")
                        }

                        let nix_completer = {|spans: list<string>|
                            let current_arg = $spans | length | $in - 1
                            with-env {NIX_GET_COMPLETIONS: $current_arg} { $spans | skip 1 | nix ...$in }
                            | lines
                            | skip 1
                            | parse "{value}\t{description}"
                        }

                        let carapace_completer = {|spans: list<string>|
                            carapace ($spans | first) nushell ...$spans
                            | try { from json }
                            | if ($in | default [] | any {|| $in.display | str starts-with ERR }) { null } else { $in }
                        }

                        let external_completer = {|spans: list<string>|
                            # if the current command is an alias, get it's expansion
                            let expanded_alias = (scope aliases | where name == $spans.0 | $in.0?.expansion?)

                            # overwrite
                            let spans = if $expanded_alias != null {
                                # put the first word of the expanded alias first in the span
                                $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
                            } else {
                                $spans | skip 1 | prepend ($spans.0)
                            }

                            match ($spans | first) {
                                nix => $nix_completer
                                _ => $carapace_completer
                            } | do $in $spans
                        }
                    '';

                settings.completions = {
                    case_sensitive = false;
                    quick = true;
                    partial = true;
                    algorithm = "prefix";
                    external.completer = lib.mkNushellInline "$external_completer";
                };
            };

            preserveHome.directories = lib.singleton ".config/carapace";
        };
}
