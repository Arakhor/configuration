{
    gaming = {
        programs.gamescope = {
            enable = true;
            capSysNice = false;
            args = [
                "-f"
                "--mangoapp"
                "--hdr-enabled"
                "--hdr-itm-enable"
                "--hide-cursor-delay"
                "3000"
                "--fade-out-duration"
                "200"
                "--xwayland-count"
                "2"
                "-W"
                "2560"
                "-H"
                "1600"
                "-O"
                "*,eDP-2"
            ];
            env = {
                DXVK_HDR = "1";
                ENABLE_GAMESCOPE_WSI = "1";

                PROTON_ENABLE_HDR = "1";
            };
        };
        programs.steam.gamescopeSession.enable = true;
    };

    zeph.programs.gamescope.args = [
        "--adaptive-sync"
        "-O eDP-2"
        "-W 2560"
        "-H 1600"
        "-r 240"
    ];
}
