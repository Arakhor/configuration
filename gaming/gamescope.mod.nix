{
    gaming = {
        programs.gamescope = {
            enable = true;
            capSysNice = false;
            args = [
                "-f"
                "--mangoapp"

            ];
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
