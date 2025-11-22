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
          limine = {
            enable = true;
            efiSupport = true;
            style.wallpapers = [ ./blahaj-blue.png ];
            maxGenerations = 10;
            secureBoot.enable = true;
            panicOnChecksumMismatch = true;
          };
          # timeout = 0;
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
