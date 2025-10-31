{
    personal =
        { nixosConfig, ... }:
        {
            services.libinput.enable = true;

            home.programs.niri.settings.input = {
                keyboard.xkb.layout = nixosConfig.locale.keyboard-layout;
                touchpad = {
                    dwt = true;
                    tap = false;
                    natural-scroll = true;
                    click-method = "clickfinger";
                    accel-profile = "flat";
                    accel-speed = 0.0;
                };
            };

            services.keyd = {
                enable = true;
                keyboards = {
                    default = {
                        ids = [ "*" ];
                        settings = {
                            global.overload_tap_timeout = 200; # Milliseconds to register a tap before timeout
                            main = {
                                capslock = "overload(control, esc)";
                                space = "overloadt(shift, space, 200)";
                                leftcontrol = "capslock";
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
        };

}
