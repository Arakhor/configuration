{
    crane,
    sources,
    rust-overlay,
    ...
}:
{
    universal =
        {
            pkgs,
            config,
            lib,
            ...
        }:
        let
            inherit (lib.kdl)
                node
                plain
                leaf
                flag
                generator
                ;
            generateKdl =
                name: document:
                pkgs.callPackage generator {
                    name = name;
                    document = document;
                };
        in
        {
            nixpkgs.overlays = [
                rust-overlay.overlays.default
                (
                    final: prev:
                    let
                        rustWithWasiTarget = final.rust-bin.stable.latest.default.override {
                            extensions = [
                                "rust-src"
                                "rust-std"
                            ];
                            targets = [ "wasm32-wasip1" ];
                        };
                        craneLib = (crane.mkLib final).overrideToolchain rustWithWasiTarget;
                        build =
                            src:
                            craneLib.buildPackage {
                                src = craneLib.cleanCargoSource src;
                                cargoExtraArgs = "--target wasm32-wasip1";

                                doCheck = false;
                                doNotSign = true;

                                buildInputs = [ final.libiconv ];
                            };
                    in
                    {
                        zellijPlugins = {
                            zjstatus = build sources.zjstatus;
                            autolock = build sources.zellij-autolock;
                        };
                    }
                )
            ];

            environment.systemPackages = [ pkgs.zellij ];
            maid-users.file.xdg_config = {
                "zellij/config.kdl".source = generateKdl "config.kdl" [
                    (leaf "default_layout" "arakhor")
                    (leaf "copy_command" "osc copy")
                    (leaf "mouse_mode" true)
                    (leaf "show_startup_tips" false)

                    (leaf "pane_frames" false)

                    (plain "ui" [
                        (plain "pane_frames" [
                            (leaf "rounded_corners" true)
                            (leaf "hide_session_name" true)
                        ])
                    ])

                    (leaf "theme" "ansi")

                    (plain "plugins" [
                        (node "autolock" { location = "file:${pkgs.zellijPlugins.autolock}/bin/zellij-autolock.wasm"; } [
                            (leaf "is_enabled" true)
                            (leaf "triggers" "hx|fzf|tv|git")
                            (leaf "reaction_seconds" "0.3")
                        ])
                        (leaf "zjstatus" { location = "file:${pkgs.zellijPlugins.zjstatus}/bin/zjstatus.wasm"; })
                    ])

                    (plain "load_plugins" [
                        (flag "autolock")
                    ])

                    (node "keybinds" { clear-defaults = true; } [
                        (plain "shared" [
                            (node "bind" "Alt f " [ (flag "ToggleFloatingPanes") ])
                        ])
                        (node "shared_except" "locked" [
                            (node "bind" "Ctrl C" [ (flag "Copy") ])
                        ])
                    ])

                ];

                "zellij/layouts/arakhor.kdl".source = generateKdl "arakhor.kdl" [
                    (plain "layout" [
                        (plain "default_tab_template" [
                            (flag "children")
                            (plain "floating_panes" [
                                (node "pane"
                                    {
                                        command = "test";
                                        close_on_exit = true;
                                    }
                                    [
                                        (leaf "x" "0")
                                        (leaf "y" "50%")
                                        (leaf "width" "100%")
                                        (leaf "height" "50%")
                                    ]
                                )
                            ])
                            # (node "pane"
                            #     {
                            #         size = 2;
                            #         borderless = true;
                            #     }
                            #     [
                            #         (node "plugin" { location = "zjstatus"; } [
                            #             (leaf "format_left" "${builtins.concatStringsSep "" [
                            #                 "{mode}"
                            #                 "{tabs}"
                            #             ]}")
                            #             (leaf "format_right" "${builtins.concatStringsSep "" [
                            #                 "#[fg=white,bg=black] {datetime} "
                            #                 "#[fg=cyan,bg=black,bold]   #[fg=black,bg=cyan] {command_hostname} "
                            #             ]}")

                            #             (leaf "mode_normal" "#[fg=black,bg=green,bold] 󰳨 NORMAL ")
                            #             (leaf "mode_locked" "#[fg=black,bg=red,bold] 󰔌 LOCKED ")
                            #             (leaf "mode_resize" "#[fg=black,bg=green,bold] 󰊓 RESIZE ")
                            #             (leaf "mode_pane" "#[fg=black,bg=blue,bold] 󰖲  PANE  ")
                            #             (leaf "mode_tab" "#[fg=black,bg=yellow,bold] 󰓩  TAB   ")
                            #             (leaf "mode_scroll" "#[fg=black,bg=cyan,bold] 󰮾 SCROLL ")
                            #             (leaf "mode_session" "#[fg=black,bg=red,bold] 󰙅  SESH  ")
                            #             (leaf "mode_move" "#[fg=black,bg=magenta,bold] 󰮴  MOVE  ")
                            #             (leaf "mode_tmux" "#[fg=black,bg=green,bold] 󰬛  TMUX  ")

                            #             (leaf "tab_active" " #[bg=green] #[fg=white,bg=black,bold] {name} ")
                            #             (leaf "tab_normal" " #[bg=white] #[fg=white,bg=black] {name} ")

                            #             (leaf "border_enabled" true)
                            #             (leaf "border_char" "━")
                            #             (leaf "border_format" "#[fg=black,bold]{char}")
                            #             (leaf "border_position" "top")

                            #             (leaf "datetime" "{format}")
                            #             (leaf "datetime_format" "%a, %d.%m.%Y %H:%M")
                            #             (leaf "datetime_timezone" config.locale.timezone)

                            #             (leaf "command_git_branch_command" "git rev-parse --abbrev-ref HEAD")
                            #             (leaf "command_git_branch_" "#[fg=red] {stdout} ")
                            #             (leaf "command_git_branch_" 10)

                            #             (leaf "command_hostname_command" "hostname")
                            #             (leaf "command_hostname_format" "{stdout}")
                            #             (leaf "command_hostname_interval" 0)
                            #         ])
                            #     ]
                            # )
                        ])
                        # (node "tab" { name = "󰇥"; } [ (leaf "pane" { command = "yazi"; }) ])
                        (node "tab" {
                            name = "󰙅 CLI";
                            focus = true;
                        } [ (flag "pane") ])
                    ])
                ];
            };
        };
}
