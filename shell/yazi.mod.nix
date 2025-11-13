{
    universal =
        {
            nixosConfig,
            pkgs,
            lib,
            ...
        }:
        let
            yazi-wrapped = pkgs.yazi.override {
                plugins = {
                    inherit (pkgs.yaziPlugins)
                        restore
                        recycle-bin
                        starship
                        git
                        piper
                        mediainfo
                        ;
                };

                initLua = # lua
                    pkgs.writeText "init.lua" ''
                        require("starship"):setup()
                        require("git"):setup()
                        require("session"):setup {
                        	sync_yanked = true,
                        }
                        require("zoxide"):setup {
                        	update_db = true,
                        }
                    '';

                settings = {
                    yazi = {
                        plugin.prepend_fetchers =
                            let
                                fetcher = id: run: name: { inherit id run name; };
                            in
                            [
                                (fetcher "git" "git" "*")
                                (fetcher "git" "git" "*/")
                            ];
                        plugin.prepend_previewers =
                            let
                                previewer = type: match: run: {
                                    inherit run;
                                    ${type} = match;
                                };
                            in
                            [
                                (previewer "name" "*.nu"
                                    ''piper -- CLICOLOR=1 /run/current-system/sw/bin/nu -c "open $1 | nu-highlight"''
                                )
                                (previewer "name" "*/"
                                    ''piper -- ${lib.getExe pkgs.eza} -TL=3 --color=always --icons=always --group-directories-first --no-quotes "$1"''
                                )
                                (previewer "mime" "image,audio,video}/*" "mediainfo")
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
                                ];
                            };
                        };

                    # theme = {
                    #   completion = {
                    #     active = {
                    #       bg = "#283457";
                    #       fg = "#c0caf5";
                    #     };
                    #     border = {
                    #       fg = "#0db9d7";
                    #     };
                    #     icon_command = "";
                    #     icon_file = "";
                    #     icon_folder = "";
                    #     inactive = {
                    #       fg = "#c0caf5";
                    #     };
                    #   };
                    #   confirm = {
                    #     border = {
                    #       fg = "#0db9d7";
                    #     };
                    #     btn_labels = [
                    #       "  [Y]es  "
                    #       "  (N)o  "
                    #     ];
                    #     btn_no = { };
                    #     btn_yes = {
                    #       bg = "#283457";
                    #     };
                    #     content = { };
                    #     list = { };
                    #     title = {
                    #       fg = "#27a1b9";
                    #     };
                    #   };
                    #   filetype = {
                    #     rules = [
                    #       {
                    #         fg = "#e0af68";
                    #         mime = "image/*";
                    #       }
                    #       {
                    #         fg = "#bb9af7";
                    #         mime = "{audio,video}/*";
                    #       }
                    #       {
                    #         fg = "#f7768e";
                    #         mime = "application/*zip";
                    #       }
                    #       {
                    #         fg = "#f7768e";
                    #         mime = "application/x-{tar,bzip*,7z-compressed,xz,rar}";
                    #       }
                    #       {
                    #         fg = "#7dcfff";
                    #         mime = "application/{pdf,doc,rtf,vnd.*}";
                    #       }
                    #       {
                    #         bg = "#f7768e";
                    #         is = "orphan";
                    #         name = "*";
                    #       }
                    #       {
                    #         fg = "#9ece6a";
                    #         is = "exec";
                    #         name = "*";
                    #       }
                    #       {
                    #         fg = "#7aa2f7";
                    #         name = "*/";
                    #       }
                    #     ];
                    #   };
                    #   help = {
                    #     footer = {
                    #       bg = "#1a1b26";
                    #       fg = "#c0caf5";
                    #     };
                    #     hovered = {
                    #       bg = "#292e42";
                    #     };
                    #     on = {
                    #       fg = "#9ece6a";
                    #     };
                    #     run = {
                    #       fg = "#bb9af7";
                    #     };
                    #   };
                    #   input = {
                    #     border = {
                    #       fg = "#0db9d7";
                    #     };
                    #     selected = {
                    #       bg = "#283457";
                    #     };
                    #     title = {
                    #       fg = "#0db9d7";
                    #     };
                    #     value = {
                    #       fg = "#9d7cd8";
                    #     };
                    #   };
                    #   mgr = {
                    #     border_style = {
                    #       fg = "#27a1b9";
                    #     };
                    #     border_symbol = "│";
                    #     count_copied = {
                    #       bg = "#41a6b5";
                    #       fg = "#c0caf5";
                    #     };
                    #     count_cut = {
                    #       bg = "#db4b4b";
                    #       fg = "#c0caf5";
                    #     };
                    #     count_selected = {
                    #       bg = "#3d59a1";
                    #       fg = "#c0caf5";
                    #     };
                    #     cwd = {
                    #       fg = "#a9b1d6";
                    #       italic = true;
                    #     };
                    #     find_keyword = {
                    #       bg = "#ff9e64";
                    #       bold = true;
                    #       fg = "#16161e";
                    #     };
                    #     find_position = {
                    #       bg = "#192b38";
                    #       bold = true;
                    #       fg = "#0db9d7";
                    #     };
                    #     hovered = {
                    #       bg = "#292e42";
                    #     };
                    #     marker_copied = {
                    #       bg = "#73daca";
                    #       fg = "#73daca";
                    #     };
                    #     marker_cut = {
                    #       bg = "#f7768e";
                    #       fg = "#f7768e";
                    #     };
                    #     marker_marked = {
                    #       bg = "#bb9af7";
                    #       fg = "#bb9af7";
                    #     };
                    #     marker_selected = {
                    #       bg = "#7aa2f7";
                    #       fg = "#7aa2f7";
                    #     };
                    #     preview_hovered = {
                    #       bg = "#292e42";
                    #     };
                    #     tab_active = {
                    #       bg = "#292e42";
                    #       fg = "#c0caf5";
                    #     };
                    #     tab_inactive = {
                    #       bg = "#1a1b26";
                    #       fg = "#3b4261";
                    #     };
                    #     tab_width = 1;
                    #   };
                    #   mode = {
                    #     normal_alt = {
                    #       bg = "#3b4261";
                    #       fg = "#7aa2f7";
                    #     };
                    #     normal_main = {
                    #       bg = "#7aa2f7";
                    #       bold = true;
                    #       fg = "#15161e";
                    #     };
                    #     select_alt = {
                    #       bg = "#3b4261";
                    #       fg = "#bb9af7";
                    #     };
                    #     select_main = {
                    #       bg = "#bb9af7";
                    #       bold = true;
                    #       fg = "#15161e";
                    #     };
                    #     unset_alt = {
                    #       bg = "#3b4261";
                    #       fg = "#9d7cd8";
                    #     };
                    #     unset_main = {
                    #       bg = "#9d7cd8";
                    #       bold = true;
                    #       fg = "#15161e";
                    #     };
                    #   };
                    #   notify = {
                    #     icon_error = "";
                    #     icon_info = "";
                    #     icon_warn = "";
                    #     title_error = {
                    #       fg = "#db4b4b";
                    #     };
                    #     title_info = {
                    #       fg = "#0db9d7";
                    #     };
                    #     title_warn = {
                    #       fg = "#e0af68";
                    #     };
                    #   };
                    #   pick = {
                    #     active = {
                    #       bg = "#283457";
                    #       fg = "#c0caf5";
                    #     };
                    #     border = {
                    #       fg = "#27a1b9";
                    #     };
                    #     inactive = {
                    #       fg = "#c0caf5";
                    #     };
                    #   };
                    #   spot = {
                    #     border = {
                    #       fg = "#27a1b9";
                    #     };
                    #     title = {
                    #       fg = "#27a1b9";
                    #     };
                    #   };
                    #   status = {
                    #     perm_exec = {
                    #       fg = "#9ece6a";
                    #     };
                    #     perm_read = {
                    #       fg = "#e0af68";
                    #     };
                    #     perm_sep = {
                    #       fg = "#414868";
                    #     };
                    #     perm_type = {
                    #       fg = "#7aa2f7";
                    #     };
                    #     perm_write = {
                    #       fg = "#f7768e";
                    #     };
                    #     progress_error = {
                    #       fg = "#f7768e";
                    #     };
                    #     progress_label = {
                    #       bold = true;
                    #       fg = "#a9b1d6";
                    #     };
                    #     progress_normal = {
                    #       fg = "#1a1b26";
                    #     };
                    #     separator_close = "";
                    #     separator_open = "";
                    #   };
                    #   tasks = {
                    #     border = {
                    #       fg = "#27a1b9";
                    #     };
                    #     hovered = {
                    #       bg = "#283457";
                    #       fg = "#c0caf5";
                    #     };
                    #     title = {
                    #       fg = "#27a1b9";
                    #     };
                    #   };
                    #   which = {
                    #     cand = {
                    #       fg = "#7dcfff";
                    #     };
                    #     cols = 3;
                    #     desc = {
                    #       fg = "#bb9af7";
                    #     };
                    #     mask = {
                    #       bg = "#16161e";
                    #     };
                    #     rest = {
                    #       fg = "#7aa2f7";
                    #     };
                    #     separator = " ➜ ";
                    #     separator_style = {
                    #       fg = "#565f89";
                    #     };
                    #   };
                    # };
                };
            };
        in
        {
            environment.systemPackages = [
                yazi-wrapped
                pkgs.mediainfo
                pkgs.trash-cli
            ];

            programs.nushell.interactiveShellInit = # nu
                ''
                    def --env yz [...args] {
                        let tmp = (mktemp -t "yazi-cwd.XXXXXX")
                        ${lib.getExe yazi-wrapped} ...$args --cwd-file $tmp
                        let cwd = (open $tmp)
                        if $cwd != "" and $cwd != $env.PWD {
                            cd $cwd
                        }
                        rm -fp $tmp
                    }

                    $env.config.keybindings ++= [
                        {
                            name: yazi
                            modifier: control
                            keycode: char_f
                            mode: [emacs vi_normal vi_insert]
                            event: {
                                send: executehostcommand
                                cmd: "yz"
                            }
                        }
                    ]

                    $env.config.hooks.env_change.PWD = (
                        $env.config.hooks.env_change.PWD?
                        | default []
                        | append {
                            condition: { "YAZI_ID" in $env }
                            code: {|_, dir| ya emit cd $"($dir)" }
                        }
                    )
                '';

            preserveHome.directories = [ ".local/state/yazi" ];
        };
}
