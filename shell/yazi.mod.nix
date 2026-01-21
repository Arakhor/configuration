{
    universal =
        { lib, pkgs, ... }:
        {
            environment.systemPackages = [
                pkgs.mediainfo
                pkgs.trash-cli
                pkgs.starship
            ];

            programs.yazi = {
                enable = true;
                plugins = {
                    inherit (pkgs.yaziPlugins)
                        restore
                        full-border
                        recycle-bin
                        starship
                        git
                        piper
                        mediainfo
                        ;
                };

                initLua = # lua
                    pkgs.writeText "init.lua" ''
                        require("git"):setup()
                        require("full-border"):setup()
                        require("starship"):setup()
                        require("session"):setup {
                        	sync_yanked = true,
                        }
                        require("zoxide"):setup {
                        	update_db = true,
                        }
                    '';

                settings = {
                    yazi = {
                        mgr.ratio = [
                            1
                            2
                            3
                        ];
                        plugin.prepend_fetchers =
                            let
                                fetcher = id: run: name: { inherit id run name; };
                            in
                            [
                                (fetcher "git" "git" "*")
                                (fetcher "git" "git" "*/")
                            ];
                        plugin.prepend_preloaders =
                            let
                                preloader = type: match: run: {
                                    inherit run;
                                    ${type} = match;
                                };
                            in
                            [
                                (preloader "mime" "{image,audio,video}/*" "mediainfo")
                                (preloader "mime" "application/x-subrip" "mediainfo")
                            ];
                        plugin.prepend_previewers =
                            let
                                previewer = type: matcher: run: {
                                    inherit run;
                                    ${type} = matcher;
                                };
                            in
                            [
                                (previewer "url" "*/" ''piper -- nucat "$1" -c "$w" -r "$h"'')
                                # (previewer "name" "*" ''piper -- nucat "$1" -c "$w" -r "$h"'')
                                (previewer "mime" "text/*" ''piper -- nucat "$1"'')
                                (previewer "mime" "application/{mbox,javascript,wine-extension-ini}" ''piper -- nucat "$1"'')
                                (previewer "mime" "{image,audio,video}/*" "mediainfo")
                                (previewer "mime" "application/x-subrip" "mediainfo")
                            ];
                    };

                    keymap =
                        let
                            bind = on: run: desc: { inherit on run desc; };
                        in
                        {
                            mgr = {
                                prepend_keymap = [
                                    (bind [ "R" "o" ] "plugin recycle-bin -- open" "Open Trash")
                                    (bind [ "R" "e" ] "plugin recycle-bin -- empty" "Empty Trash")
                                    (bind [ "R" "D" ] "plugin recycle-bin -- emptyDays" "Empty by days deleted")
                                    (bind [ "R" "d" ] "plugin recycle-bin -- delete" "Delete from Trash")
                                    (bind [ "R" "r" ] "plugin recycle-bin -- restore" "Restore from Trash")
                                    (bind "u" "plugin restore" "Restore last deleted files/folders")
                                    (bind "<C-i>" "shell $SHELL --block" "Open $SHELL here")
                                ];
                            };
                        };

                    theme = {
                        mgr.border_style.fg = "lightblack";
                        mgr.border_symbol = "│";
                        mode =
                            let
                                mkMode = mode: color: {
                                    "${mode}_main" = {
                                        fg = "black";
                                        bg = color;
                                        bold = true;
                                    };
                                    "${mode}_alt" = {
                                        fg = color;
                                        bg = "black";
                                    };

                                };
                            in
                            lib.mergeAttrsList [
                                (mkMode "normal" "green")
                                (mkMode "select" "red")
                                (mkMode "unset" "red")
                            ];
                    };
                };
            };

            programs.nushell =
                let
                    inherit (lib.nushell) mkNushellInline;
                in
                {
                    settings = {
                        hooks.env_change.PWD = [
                            (mkNushellInline ''
                                {
                                  condition: { "YAZI_ID" in $env }
                                  code: {|_, dir| ya emit cd $"($dir)" }
                                }
                            '')
                        ];

                        keybindings = [
                            {
                                name = "yazi";
                                modifier = "control";
                                keycode = "char_f";
                                event = {
                                    send = "executehostcommand";
                                    cmd = "if \"YAZI_ID\" not-in $env { yz } else { exit }";
                                };
                                mode = [
                                    "emacs"
                                    "vi_normal"
                                    "vi_insert"
                                ];
                            }
                        ];
                    };

                    initConfig = # nu
                        ''
                            def --env yz [...args] {
                                let tmp = (mktemp -t "yazi-cwd.XXXXXX")
                                yazi ...$args --cwd-file $tmp
                                let cwd = (open $tmp)
                                if $cwd != "" and $cwd != $env.PWD {
                                    cd $cwd
                                }
                                rm -fp $tmp
                            }
                        '';
                };

            preserveHome.directories = [ ".local/state/yazi" ];
        };
}
