{
    graphical =
        { pkgs, lib, ... }:
        {
            maid-users.packages = [
                pkgs.spotify
                (lib.hiPrio (
                    pkgs.runCommand "spotify-desktop-rename" { } ''
                        mkdir -p $out/share/applications
                        substitute ${pkgs.spotify}/share/applications/spotify.desktop $out/share/applications/spotify.desktop \
                          --replace-fail "Name=Spotify" "Name=Spotify Desktop"
                    ''
                ))
            ];

            programs.uwsm.appUnitOverrides."spotify@.service" = ''
                [Service]
                KillMode=mixed
            '';

            preserveHome.directories = [
                ".config/spotify"
                ".cache/spotify"
            ];
        };
}
