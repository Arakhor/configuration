{
    universal =
        {
            config,
            pkgs,
            lib,
            ...
        }:
        let
            cfg = config.programs.starship;

            settingsFormat = pkgs.formats.toml { };

            userSettingsFile = settingsFormat.generate "starship.toml" cfg.settings;

            settingsFile =
                if cfg.presets == [ ] then
                    userSettingsFile
                else
                    pkgs.runCommand "starship.toml" { nativeBuildInputs = [ pkgs.yq ]; } ''
                        tomlq -s -t 'reduce .[] as $item ({}; . * $item)' \
                          ${
                              lib.concatStringsSep " " (map (f: "${cfg.package}/share/starship/presets/${f}.toml") cfg.presets)
                          } \
                          ${userSettingsFile} \
                          > $out
                    '';
        in
        {
            wrappers.starship = {
                basePackage = pkgs.starship;
                env.STARSHIP_CONFIG.value = (
                    (pkgs.formats.toml { }).generate "starship.toml" config.programs.starship.settings
                );
            };

            programs.starship = {
                enable = true;
                transientPrompt = {
                    enable = true;
                    left = "${lib.getExe cfg.package} module character";
                    right = "${lib.getExe cfg.package} module time";
                };
                settings =
                    let
                        mkSurround =
                            contents:
                            {
                                left ? "[",
                                right ? "]",
                                padLeft ? false,
                                padRight ? false,
                                color ? "bright-black",
                            }:
                            (if padLeft then " " else "")
                            + (if left != null then "[\\${left}](fg:${color})" else "")
                            + contents
                            + (if right != null then "[\\${right}](fg:${color})" else "")
                            + (if padRight then " " else "");

                        # NOTE: Shortcuts for adding dark-gray square brackets around a block.
                        mkContainer = contents: mkSurround contents { padRight = true; };
                        mkContainerRight = contents: mkSurround contents { padLeft = false; };
                    in
                    {
                        add_newline = true;

                        username = {
                            style_user = "purple";
                            style_root = "bold red";
                            format = "[($user)]($style)";
                        };

                        hostname = {
                            ssh_symbol = "SSH:";
                            style = "bold blue";
                            format = "[$ssh_symbol](fg:cyan)[$hostname]($style)";
                        };

                        directory =
                            let
                                baseFormat = "[$path]($style) [$read_only]($read_only_style)";
                            in
                            {
                                format = "[ ]($style)${baseFormat}";
                                repo_root_format = "[ ]($style)[git:](fg:yellow)[$repo_root]($repo_root_style)${baseFormat}";
                                truncation_length = 6;
                                style = "fg:cyan";
                                before_repo_root_style = "bold fg:cyan";
                                repo_root_style = "bold bright-white";
                                read_only = " RO";
                                read_only_style = "bold fg:red";
                            };

                        character = {
                            success_symbol = "[](bold fg:bright-green)";
                            vimcmd_symbol = "[](bold fg:bright-cyan)";
                            error_symbol = "[](bold fg:bright-red)";
                        };

                        git_branch = {
                            format = mkContainer "[$symbol$branch(:$remote_branch)]($style)";
                            symbol = "";
                        };

                        git_metrics = {
                            format = "([+$added]($added_style))([-$deleted]($deleted_style) )";
                            added_style = "bold fg:purple";
                            deleted_style = "bold fg:red";
                            disabled = false;
                        };

                        git_status = {
                            format = "([$all_status$ahead_behind]($style) )";
                            conflicted = "=";
                            ahead = "";
                            behind = "";
                            diverged = "󰓢";
                            up_to_date = "";
                            untracked = "?";
                            stashed = "";
                            modified = "~";
                            staged = "+";
                            renamed = ">";
                            deleted = "-";
                            typechanged = "";
                            style = "fg:yellow";
                        };

                        rust = {
                            format = mkContainer "[$symbol $numver]($style)";
                            symbol = "󱘗";
                            style = "fg:red";
                        };

                        package = {
                            format = mkContainer "[$symbol$version]($style)";
                            style = "fg:blue";
                        };

                        status = {
                            disabled = false;
                            format = "[$status]($style) ";
                        };

                        time = {
                            format = mkContainerRight "[$time]($style)";
                            time_format = "%H:%M %p";
                            style = "fg:bright-black";
                            disabled = false;
                        };

                        cmd_duration = {
                            format = "[ $duration]($style) ";
                            style = "fg:white";
                        };

                        direnv = {
                            format = "([$loaded]($style) )";
                            loaded_msg = " ";
                            style = "fg:bright-black";
                            disabled = false;
                        };

                        nix_shell = {
                            format = "[󱄅 ]($style) ";
                            pure_msg = "";
                            impure_msg = "";
                            symbol = "";
                        };

                        fill.symbol = " ";

                        aws.disabled = true;
                        aws.symbol = "󰸏 ";
                        buf.symbol = " ";
                        c.symbol = " ";
                        conda.symbol = "󰕗 ";
                        crystal.symbol = " ";
                        dart.symbol = " ";
                        docker_context.symbol = "󰡨 ";
                        elixir.symbol = " ";
                        elm.symbol = " ";
                        fennel.symbol = " ";
                        fossil_branch.symbol = "󰘬 ";
                        golang.symbol = "󰟓 ";
                        gradle.symbol = " ";
                        guix_shell.symbol = " ";
                        haskell.symbol = "󰲒 ";
                        haxe.symbol = " ";
                        hg_branch.symbol = "󰘬 ";
                        java.symbol = "󰬷 ";
                        julia.symbol = " ";
                        kotlin.symbol = "󱈙 ";
                        lua.symbol = "󰢱 ";
                        memory_usage.symbol = " ";
                        meson.symbol = "󰔷 ";
                        nim.symbol = " ";
                        nodejs.symbol = "󰎙 ";
                        ocaml.symbol = " ";
                        package.symbol = "󰏗 ";
                        perl.symbol = " ";
                        php.symbol = "󰌟 ";
                        pijul_channel.symbol = "󰘬 ";
                        python.symbol = "󰌠 ";
                        rlang.symbol = "󰟔 ";
                        ruby.symbol = "󰴭 ";
                        scala.symbol = " ";
                        swift.symbol = "󰛥 ";
                        zig.symbol = " ";

                        format = builtins.replaceStrings [ "\n" ] [ "" ] ''
                            (
                            [\[](fg:bright-black)
                            $hostname
                            [@](fg:bright-black)
                            $username
                            [\] ](fg:bright-black)
                            )

                            $localip
                            $shlvl
                            $singularity
                            $kubernetes
                            $directory
                            $vcsh
                            $fossil_branch
                            $fossil_metrics
                            $git_branch
                            $git_commit
                            $git_state
                            $hg_branch
                            $pijul_channel
                            $docker_context
                            $c
                            $cmake
                            $cobol
                            $daml
                            $dart
                            $deno
                            $dotnet
                            $elixir
                            $elm
                            $erlang
                            $fennel
                            $gleam
                            $golang
                            $guix_shell
                            $haskell
                            $haxe
                            $helm
                            $java
                            $julia
                            $kotlin
                            $gradle
                            $lua
                            $nim
                            $nodejs
                            $ocaml
                            $opa
                            $perl
                            $php
                            $pulumi
                            $purescript
                            $python
                            $quarto
                            $raku
                            $rlang
                            $red
                            $ruby
                            $rust
                            $scala
                            $solidity
                            $swift
                            $terraform
                            $typst
                            $vlang
                            $vagrant
                            $zig
                            $buf
                            $nix_shell
                            $conda
                            $meson
                            $spack
                            $memory_usage
                            $aws
                            $gcloud
                            $openstack
                            $azure
                            $nats
                            $direnv
                            $env_var
                            $crystal
                            $package
                            $custom
                            $sudo

                            $line_break

                            $jobs
                            $battery
                            $os
                            $container
                            $shell
                            $character
                        '';

                        right_format = builtins.replaceStrings [ "\n" ] [ "" ] ''
                            $status
                            $cmd_duration
                            $git_status
                            $git_metrics
                            $time
                        '';
                    };
            };

            programs.nushell.extraConfig =
                # nu
                ''
                    export-env {
                      $env.config.render_right_prompt_on_last_line = true

                      $env.STARSHIP_CONFIG = "${settingsFile}"
                      $env.STARSHIP_SESSION_KEY = (random chars -l 16)
                      $env.STARSHIP_SHELL = "nu"

                      # HACK:
                      #
                      # Render character module separately from prompt
                      # this allows vi-mode indicator to work on nushell

                      def _indicator [
                        --vicmd (-v)
                      ] {
                        $env.STARSHIP_SHELL = "zsh"
                        let status = $"--status=($env.LAST_EXIT_CODE)"

                        if $vicmd {
                          ${lib.getExe cfg.package} module character --keymap vicmd $status
                        } else {
                          ${lib.getExe cfg.package} module character $status
                        }
                      }

                      def --wrapped _prompt [...rest] {
                        (
                          ^${lib.getExe cfg.package} prompt
                          $"--cmd-duration=(if $env.CMD_DURATION_MS == "0823" { 0 } else { $env.CMD_DURATION_MS })"
                          $"--status=($env.LAST_EXIT_CODE)"
                          $"--terminal-width=((term size).columns)"
                          $"--jobs=(job list | length)"
                          ...$rest
                        ) | str replace (_indicator) ""
                      }

                      $env.PROMPT_INDICATOR = {|| _indicator }
                      $env.PROMPT_INDICATOR_VI_INSERT = {|| _indicator }
                      $env.PROMPT_INDICATOR_VI_NORMAL = {|| _indicator -v }
                      $env.PROMPT_MULTILINE_INDICATOR = {|| _prompt --continuation }

                      $env.PROMPT_COMMAND = {|| _prompt }
                      $env.PROMPT_COMMAND_RIGHT = {|| _prompt --right }

                      ${lib.optionalString cfg.transientPrompt.enable # nu
                          ''
                              $env.TRANSIENT_PROMPT_INDICATOR = ""
                              $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = ""
                              $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = ""
                              $env.TRANSIENT_PROMPT_COMMAND = {|| ${cfg.transientPrompt.left} }
                              $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| ${cfg.transientPrompt.right} }
                          ''
                      }
                    }          
                '';

            preserveHome.directories = [ ".cache/starship" ];
        };
}
