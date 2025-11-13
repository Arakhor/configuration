{
  personal =
    { pkgs, lib, ... }:
    {
      programs.seahorse.enable = true;
      services.gnome.gnome-keyring.enable = true;
      home = {
        systemd.services.gnome-keyring = {
          description = "GNOME Keyring";
          partOf = [ "graphical-session-pre.target" ];
          serviceConfig = {
            ExecStart = "${lib.getExe' pkgs.gnome-keyring "gnome-keyring-daemon"} ${
              lib.concatStringsSep " " [
                "--start"
                "--foreground"
                "--components=pkcs11,secrets,ssh"
              ]
            }";
            Restart = "on-abort";
          };
          wantedBy = [ "graphical-session-pre.target" ];
        };
      };

      preserveHome.directories = [
        {
          directory = ".local/share/keyrings";
          mode = "0700";
        }
        {
          directory = ".gnupg";
          mode = "0700";
        }
      ];
    };
}
