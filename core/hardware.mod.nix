{
    disko,
    ...
}:
{
    universal =
        {
            lib,
            config,
            ...
        }:
        {
            imports = [ disko.nixosModules.disko ];

            # Enable fwupd for firmware updates across devices
            services.fwupd.enable = true;

            # Power management
            services.upower =
                let
                    isLaptop = config.hardware.facter.report.hardware.system.form_factor == "laptop";
                in
                {
                    enable = isLaptop;
                    percentageLow = 15;
                    percentageCritical = 5;
                    percentageAction = 3;
                };
            systemd.services.upower.wantedBy = lib.mkIf config.services.upower.enable [ "graphical.target" ];
            services.power-profiles-daemon.enable = true;

            services.keyd = {
                enable = true;
                keyboards = {
                    default = {
                        ids = [ "*" ];
                        settings = {
                            global.overload_tap_timeout = 200; # Milliseconds to register a tap before timeout
                            main = {
                                capslock = "overload(control, esc)";
                            };
                            navigation = {
                                h = "left";
                                j = "down";
                                k = "up";
                                l = "right";
                                u = "pageup";
                                d = "pagedown";
                            };
                        };
                    };
                };
            };

            # Enable support for gaming peripherals and input devices
            hardware.xpadneo.enable = true;
            hardware.i2c.enable = true;
            hardware.brillo.enable = true;
            hardware.steam-hardware.enable = true;
            hardware.logitech.wireless.enable = true;
            hardware.logitech.wireless.enableGraphical = true;

            # Bluetooth configuration
            # services.blueman.enable = true;
            hardware.bluetooth.settings = {
                General = {
                    Privacy = "device";
                    JustWorksRepairing = "always";
                    Class = "0x000100";
                    FastConnectable = "true";
                };
            };

            # User groups for hardware access
            users.users.arakhor.extraGroups = [
                "i2c"
                "i2c-dev"
                "video"
            ];

            preserveSystem.directories = [
                "/var/lib/power-profiles-daemon"
                "/var/lib/fwupd"
                "/var/lib/bluetooth"
            ];
        };

    xps = {
        networking.hostName = "xps";
        hardware.facter.reportPath = ./hardware-scans/xps.json;

        # Enable periodic TRIM for SSD health
        services.fstrim.enable = true;

        # Thermal daemon for temperature management
        services.thermald.enable = true;

        # Optimize suspend behavior by reducing image size allocation
        systemd.tmpfiles.rules = [
            "w /sys/power/image_size - - - - 0"
        ];
    };

    zeph = {
        networking.hostName = "zeph";
        hardware.facter.reportPath = ./hardware-scans/zeph.json;
    };
}
