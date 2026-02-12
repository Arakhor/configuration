{
    graphical =
        {
            pkgs,
            lib,
            config,
            ...
        }:
        {
            environment.systemPackages = [ pkgs.playerctl ];

            maid-users.systemd.services.playerctld = {
                description = "MPRIS media player daemon";
                serviceConfig = {
                    ExecStart = "${pkgs.playerctl}/bin/playerctld";
                    Type = "dbus";
                    BusName = "org.mpris.MediaPlayer2.playerctld";
                };
                wantedBy = [ "default.target" ];
            };
        };
}
