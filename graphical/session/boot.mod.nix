{
    graphical =
        { pkgs, ... }:
        {
            boot = {
                initrd = {
                    systemd.enable = true;
                    verbose = false;
                };

                consoleLogLevel = 0;

                kernelParams = [
                    "quiet"
                    "loglevel=3"
                    "systemd.show_status=auto"
                    "rd.udev.log_level=3"
                    "udev.log_level=3"
                    "vt.global_cursor_default=0"
                ];
                loader = {
                    efi.canTouchEfiVariables = true;
                    systemd-boot = {
                        enable = true;
                        editor = false;
                        consoleMode = "max";
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
        };
}
