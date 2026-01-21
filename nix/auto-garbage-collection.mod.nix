{
    universal =
        { lib, config, ... }:
        {
            options.do-auto-garbage-collection = lib.mkEnableOption "auto garbage collection";

            config = lib.mkIf config.do-auto-garbage-collection {

                programs.nh.clean = {
                    enable = true;
                    extraArgs = "--keep 3 --keep-since 7d";
                    # this is somewhere in the middle of my commute to school.
                    # and if i'm not at school, i'm likely asleep.
                    dates = "Mon..Fri *-*-* 07:00:00";
                };

                nix.optimise = {
                    automatic = true;
                    # why is that a list?
                    dates = [ "Mon..Fri *-*-* 07:30:00" ];
                };

                # I don't want these to be persistent or have any delay.
                # They don't need to run daily; if they miss a day, it's fine.
                # And i don't want them to ever delay until e.g. i'm at school
                # because that will impact my workflow if i want to remote in.
                systemd.timers =
                    let
                        fuck-off.timerConfig = {
                            Persistent = lib.mkForce false;
                            RandomizedDelaySec = lib.mkForce 0;
                        };
                    in
                    {
                        nh-clean = fuck-off;
                        nix-optimise = fuck-off;
                    };
            };
        };

    xps.do-auto-garbage-collection = true;
    zeph.do-auto-garbage-collection = true;
}
