{
    gaming =
        {
            pkgs,
            lib,
            ...
        }:
        {
            # Do not start gamemoded for system users. This prevents gamemoded starting
            # during login when greetd temporarily runs as the greeter user.
            systemd.user.services.gamemoded.unitConfig.ConditionUser = "!@system";

            # Since version 1.8 gamemode requires the user to be in the gamemode group
            # https://github.com/FeralInteractive/gamemode/issues/452
            users.users.arakhor.extraGroups = [ "gamemode" ];

            environment.sessionVariables.GAMEMODERUNEXEC = "nvidia-offload";

            programs.gamemode = {
                enable = true;
                settings = {
                    general = {
                        softrealtime = "auto";
                        # desiredgov = "performance";
                        # desiredprof = "performance";
                    };
                    gpu.apply_gpu_optimisations = "accept-responsibility";

                    custom =
                        let
                            startStopScript =
                                mode:
                                let
                                    tern = ifStart: ifEnd: if mode == "start" then ifStart else ifEnd;
                                    noctalia = "${pkgs.noctalia-shell}/bin/noctalia-shell";
                                in
                                pkgs.writers.writeNuBin "gamemode-${mode}" # nu
                                    ''
                                        ${noctalia} ipc call powerProfile ${tern "enableNoctaliaPerformance" "disableNoctaliaPerformance"}
                                        ${noctalia} ipc call powerProfile set ${tern "performance" "balanced"}
                                    '';
                        in
                        {
                            start = lib.getExe (startStopScript "start");
                            end = lib.getExe (startStopScript "end");
                        };
                };
            };
        };
}
