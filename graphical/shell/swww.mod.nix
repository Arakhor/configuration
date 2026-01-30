{
    graphical =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        {
            style.wallpaper =
                let
                    # TODO: transition fps
                    transition = "--transition-bezier .43,1.19,1,.4 --transition-type center --transition-duration 1 --transition-fps 240";
                in
                {
                    wallpaperUnit = "swww.service";
                    setWallpaperCommand = "${lib.getExe pkgs.swww} img ${transition}";
                };

            maid-users.systemd.services.swww = {
                description = "Swww Wallpaper Daemon";
                before = [ "set-wallpaper.service" ];
                partOf = [ "graphical-session.target" ];
                requisite = [ "graphical-session.target" ];
                after = [ "graphical-session.target" ];

                serviceConfig = {
                    Slice = config.lib.session.backgroundSlice;
                    ExecStart = "${lib.getExe' pkgs.swww "swww-daemon"} --quiet --no-cache";
                };

                wantedBy = [ "graphical-session.target" ];
            };
        };
}
