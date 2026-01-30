{
    graphical =
        { pkgs, ... }:
        {
            environment.systemPackages = [
                pkgs.pwvucontrol
            ];

            security.rtkit.enable = true;
            services.pipewire = {
                enable = true;
                alsa.enable = true;
                alsa.support32Bit = true;
                pulse.enable = true;
                jack.enable = true;
                #media-session.enable = true;
                extraConfig.pipewire."99-low-latency" = {
                    context.properties = {
                        default = {
                            clock = {
                                rate = 48000;
                                quantum = 512;
                                min-quantum = 256;
                                max-quantum = 8192;
                            };
                        };
                    };
                };
            };

            # this is the loopback device created in ALSA.
            # it's just annoying, and i can create loopbacks on demand with `pw-loopback`.
            boot.blacklistedKernelModules = [ "snd_aloop" ];

            # Bluetooth audio devices come with multiple profiles:
            # One important profile is the "headset" profile, which has a microphone (as opposed to headphones with no mic)
            # and the other is the Advanced Audio Distribution Profile (A2DP), which is used for high quality audio.
            # The headset profile has absolutely terrible audio quality, and i never want to use it.
            # And, my computer has a separate microphone anyway, so i don't need the headset profile's microphone.
            # Let's just never switch to the headset profile.
            services.pipewire.wireplumber.extraConfig."51-mitigate-annoying-profile-switch" = {
                "wireplumber.settings" = {
                    "bluetooth.autoswitch-to-headset-profile" = false;
                };
            };

            # Some apps fuck with settings that i don't want to persist.
            # My whole audio setup should be configured statically.
            # TODO: actually configure volumes (raw mic 60%, rnnoise 130%)
            services.pipewire.wireplumber.extraConfig."51-stop-restoring-shit-you-cunt" = {
                "wireplumber.settings" = {
                    "device.restore-profile" = false;
                    "device.restore-routes" = false;
                    "node.stream.restore-props" = false;
                    "node.stream.restore-target" = false;
                    "node.restore-default-targets" = false;
                };
            };

            # It's discord. It's discord's Automatic Gain Control. That's the fucker.
            # I turned it off. I think this works? It seems to respect that.
            # But i don't EVER want to let this fuckass application touch my knobs.
            services.pipewire.extraConfig.pipewire-pulse."51-STOP-FUCKING-WITH-MY-SHIT" = {
                "pulse.rules" = [
                    {
                        "match" = [ { "application.process.binary" = "vesktop"; } ];
                        "actions" = {
                            "quirks" = [ "block-source-volume" ];
                        };
                    }
                ];
            };
        };

    maid-users =
        { pkgs, ... }:
        {
            packages = with pkgs; [
                qpwgraph
                helvum
            ];
        };
}
