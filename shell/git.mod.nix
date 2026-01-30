{
    universal =
        {
            pkgs,
            lib,
            ...
        }:
        {
            environment.systemPackages = with pkgs; [
                gh
                git
                gitui
            ];

            programs.nushell.shellAliases = {
                g = "git";
                ga = "git add";
                gaa = "git add *";
                gb = "git branch";
                gbd = "git branch --delete";
                gbD = "git branch --delete --force";
                gco = "git checkout";
                gcp = "git cherry-pick";
                gd = "git diff";
                gf = "git fetch";
                gl = "git pull";
                gm = "git merge";
                gma = "git merge --abort";
                gp = "git push";
                gpf = "git push --force-with-lease";
                "gpf!" = "git push --force";
                grb = "git rebase";
                grba = "git rebase --abort";
                grbc = "git rebase --continue";
                gs = "git status --short --branch";
            };

            maid-users.file.xdg_config = {
                "git/config".text = lib.generators.toGitINI {
                    user = {
                        name = "arakhor";
                        email = "arakhor@proton.me";
                    };
                    init.defaultBranch = "main";
                    push.default = "current";
                    credential = {
                        "https://github.com".helper = "${pkgs.gh}/bin/gh auth git-credential";
                        "https://gist.github.com".helper = "${pkgs.gh}/bin/gh auth git-credential";
                    };
                    url = {
                        "https://github.com/".insteadOf = "gh:";
                        "https://gitlab.com/".insteadOf = "gl:";
                    };
                    advice.addIgnoredFile = false;
                };

                "git/ignore".text = lib.concatLines [
                    # general
                    "*.log"
                    ".DS_Store"
                    ".Trash-*"
                    # nix-specific
                    ".direnv/"
                    ".envrc"
                    "repl-result-dev"
                    "repl-result-doc"
                    "repl-result-info"
                    "repl-result-man"
                    "repl-result-out"
                    "result"
                    "result-dev"
                    "result-doc"
                    "result-info"
                    "result-man"
                ];

                "gitui/key_bindings.ron".text =
                    # ron
                    ''
                        // Note:
                        // If the default key layout is lower case,
                        // and you want to use `Shift + q` to trigger the exit event,
                        // the setting should like this `exit: Some(( code: Char('Q'), modifiers: "SHIFT")),`
                        // The Char should be upper case, and the modifier should be set to "SHIFT".
                        //
                        // Note:
                        // find `KeysList` type in src/keys/key_list.rs for all possible keys.
                        // every key not overwritten via the config file will use the default specified there
                        (
                            open_help: Some(( code: F(1), modifiers: "")),

                            move_left: Some(( code: Char('h'), modifiers: "")),
                            move_right: Some(( code: Char('l'), modifiers: "")),
                            move_up: Some(( code: Char('k'), modifiers: "")),
                            move_down: Some(( code: Char('j'), modifiers: "")),
                            
                            popup_up: Some(( code: Char('p'), modifiers: "CONTROL")),
                            popup_down: Some(( code: Char('n'), modifiers: "CONTROL")),
                            page_up: Some(( code: Char('b'), modifiers: "CONTROL")),
                            page_down: Some(( code: Char('f'), modifiers: "CONTROL")),
                            home: Some(( code: Char('g'), modifiers: "")),
                            end: Some(( code: Char('G'), modifiers: "SHIFT")),
                            shift_up: Some(( code: Char('K'), modifiers: "SHIFT")),
                            shift_down: Some(( code: Char('J'), modifiers: "SHIFT")),

                            edit_file: Some(( code: Char('I'), modifiers: "SHIFT")),

                            status_reset_item: Some(( code: Char('U'), modifiers: "SHIFT")),

                            diff_reset_lines: Some(( code: Char('u'), modifiers: "")),
                            diff_stage_lines: Some(( code: Char('s'), modifiers: "")),

                            stashing_save: Some(( code: Char('w'), modifiers: "")),
                            stashing_toggle_index: Some(( code: Char('m'), modifiers: "")),

                            stash_open: Some(( code: Char('l'), modifiers: "")),

                            abort_merge: Some(( code: Char('M'), modifiers: "SHIFT")),
                        )
                    '';
            };

            preserveHome.directories = [
                ".config/gh"
            ];
        };
}
