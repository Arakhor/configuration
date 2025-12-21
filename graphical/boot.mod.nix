{
  graphical =
    { pkgs, ... }:
    {
      boot = {
        kernelParams = [
          "quiet"
          "systemd.show_status=auto"
          "rd.udev.log_level=3"
          "plymouth.use-simpledrm"
        ];
        loader = {
          efi.canTouchEfiVariables = true;

          systemd-boot = {
            enable = true;
            editor = false;
            consoleMode = "auto";
            configurationLimit = 10;
          };

          timeout = 0;
        };

        plymouth = {
          enable = true;
          themePackages = [ pkgs.plymouth-blahaj-theme ];
          theme = "blahaj";
        };

      };

      environment.systemPackages = [ pkgs.sbctl ];

      preserveSystem.directories = [ "/var/lib/sbctl" ];
    };
}
