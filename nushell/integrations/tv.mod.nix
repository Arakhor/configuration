{
    universal =
        {
            config,
            pkgs,
            lib,
            ...
        }:
        let
            tomlFormat = pkgs.formats.toml { };

            settings = {
                default_channel = "files";
                global_history = false;
                history_size = 200;
                keybindings = {
                    backspace = "delete_prev_char";
                    backtab = "toggle_selection_up";
                    ctrl-a = "go_to_input_start";
                    ctrl-c = "quit";
                    ctrl-down = "select_next_history";
                    ctrl-e = "go_to_input_end";
                    ctrl-f = "cycle_previews";
                    ctrl-h = "toggle_help";
                    ctrl-j = "select_next_entry";
                    ctrl-k = "select_prev_entry";
                    ctrl-l = "toggle_layout";
                    ctrl-n = "select_next_entry";
                    ctrl-o = "toggle_preview";
                    ctrl-p = "select_prev_entry";
                    ctrl-r = "reload_source";
                    ctrl-s = "cycle_sources";
                    ctrl-t = "toggle_remote_control";
                    ctrl-u = "delete_line";
                    ctrl-up = "select_prev_history";
                    ctrl-w = "delete_prev_word";
                    ctrl-y = "copy_entry_to_clipboard";
                    delete = "delete_next_char";
                    down = "select_next_entry";
                    end = "go_to_input_end";
                    enter = "confirm_selection";
                    esc = "quit";
                    f12 = "toggle_status_bar";
                    home = "go_to_input_start";
                    left = "go_to_prev_char";
                    pagedown = "scroll_preview_half_page_down";
                    pageup = "scroll_preview_half_page_up";
                    right = "go_to_next_char";
                    tab = "toggle_selection_down";
                    up = "select_prev_entry";
                };
                shell_integration = {
                    channel_triggers = {
                        alias = [
                            "alias"
                            "unalias"
                        ];
                        dirs = [
                            "cd"
                            "ls"
                            "rmdir"
                            "z"
                        ];
                        docker-images = [ "docker run" ];
                        env = [
                            "export"
                            "unset"
                        ];
                        files = [
                            "hx"
                            "cat"
                            "less"
                            "head"
                            "tail"
                            "vim"
                            "nano"
                            "bat"
                            "cp"
                            "mv"
                            "rm"
                            "touch"
                            "chmod"
                            "chown"
                            "ln"
                            "tar"
                            "zip"
                            "unzip"
                            "gzip"
                            "gunzip"
                            "xz"
                        ];
                        git-branch = [
                            "git checkout"
                            "git branch"
                            "git merge"
                            "git rebase"
                            "git pull"
                            "git push"
                        ];
                        git-diff = [
                            "git add"
                            "git restore"
                        ];
                        git-log = [
                            "git log"
                            "git show"
                        ];
                        git-repos = [
                            "nvim"
                            "code"
                            "git clone"
                        ];
                    };
                    fallback_channel = "files";
                    keybindings = {
                        command_history = "ctrl-r";
                        smart_autocomplete = "ctrl-t";
                    };
                };
                tick_rate = 50;
                ui = {
                    help_panel = {
                        hidden = true;
                        show_categories = true;
                    };
                    input_bar = {
                        border_type = "rounded";
                        position = "top";
                        prompt = ">";
                    };
                    orientation = "landscape";
                    preview_panel = {
                        border_type = "rounded";
                        hidden = false;
                        scrollbar = true;
                        size = 50;
                    };
                    remote_control = {
                        show_channel_descriptions = true;
                        sort_alphabetically = true;
                    };
                    results_panel = {
                        border_type = "rounded";
                    };
                    status_bar = {
                        hidden = false;
                        separator_close = "";
                        separator_open = "";
                    };
                    theme = "default";
                    ui_scale = 100;
                };
            };

            channels = [
                {
                    metadata.name = "nu-history";
                    source.command = "nu -l -c 'history | get command | uniq | reverse | to text";
                }
                {
                    metadata.name = "nu-commands";
                    source.command = "nu -l -c 'help commands | select name description | to csv --noheaders";
                    source.display = "{split:,:0}";
                    source.output = "{split:,:0}";
                    preview.command = "nu -l -c 'help {split:,:0}'";
                }
                {
                    metadata.name = "nix";
                    source.command = "nix-search-tv print";
                    preview.command = "nix-search-tv preview {}";
                }
                {
                    metadata.name = "zoxide";
                    source.command = "zoxide query --list";
                    preview.command = "eza -T --icons always --color always '{}'";
                }
            ];
        in
        {
            wrappers.tv = {
                basePackage = pkgs.television;
                extraPackages = [
                    pkgs.nix-search-tv
                ];
                prependFlags = [
                    "--config-file"
                    (tomlFormat.generate "config.toml" settings)
                ];
            };
            programs.nushell = {
                settings.keybindings = [
                    {
                        name = "tv_completion";
                        modifier = "control";
                        keycode = "char_t";
                        event = {
                            send = "executehostcommand";
                            cmd = "tv_smart_autocomplete";
                        };
                        mode = [
                            "emacs"
                            "vi_normal"
                            "vi_insert"
                        ];
                    }
                    {
                        name = "tv_shell_history";
                        modifier = "control";
                        keycode = "char_r";
                        event = {
                            send = "executehostcommand";
                            cmd = "tv_shell_history";
                        };
                        mode = [
                            "emacs"
                            "vi_normal"
                            "vi_insert"
                        ];
                    }

                ];
                initConfig = # nu
                    ''
                        def tv_smart_autocomplete [] {
                            let line = (commandline)
                            let cursor = (commandline get-cursor)
                            let lhs = ($line | str substring 0..$cursor)
                            let rhs = ($line | str substring $cursor..)
                            let output = (tv --no-status-bar --inline --autocomplete-prompt $lhs | str trim)

                            if ($output | str length) > 0 {
                                let needs_space = not ($lhs | str ends-with " ")
                                let lhs_with_space = if $needs_space { $"($lhs) " } else { $lhs }
                                let new_line = $lhs_with_space + $output + $rhs
                                let new_cursor = ($lhs_with_space + $output | str length)
                                commandline edit --replace $new_line
                                commandline set-cursor $new_cursor
                            }
                        }

                        def tv_shell_history [] {
                            let current_prompt = (commandline)
                            let cursor = (commandline get-cursor)
                            let current_prompt = ($current_prompt | str substring 0..$cursor)

                            let output = (tv nu-history --no-status-bar --inline --input $current_prompt | str trim)

                            if ($output | is-not-empty) {
                                commandline edit --replace $output
                                commandline set-cursor --end
                            }
                        }
                    '';
            };
        };
}
