let
    settings = {
        keyboard-layout = "pl";
        timezone = "Europe/Warsaw";
        language = "en_DK.UTF-8";
        formats = "C.UTF-8";
        regulatory-domain = "PL";
    };
in
{
    universal =
        { config, lib, ... }:
        {
            options.locale = lib.mapAttrs (lib.const (
                value:
                lib.mkOption {
                    type = lib.types.str;
                    readOnly = true;
                    default = value;
                }
            )) settings;

            config = {
                # set time/date automatically
                # services.automatic-timezoned.enable = true;
                # services.dbus.packages = [ config.services.automatic-timezoned.package ];
                # services.geoclue2 = {
                #     enable = true;
                #     enableDemoAgent = lib.mkForce true;
                #     appConfig = {
                #         gammastep = {
                #             isAllowed = true;
                #             isSystem = false;
                #         };
                #         "nl.whynothugo.darkman" = {
                #             isAllowed = true;
                #             isSystem = false;
                #         };
                #     };
                # };

                time.timeZone = lib.mkDefault config.locale.timezone;
                console.keyMap = config.locale.keyboard-layout;

                i18n.defaultLocale = config.locale.language;
                i18n.extraLocaleSettings = {
                    LC_ADDRESS = config.locale.formats;
                    LC_IDENTIFICATION = config.locale.formats;
                    LC_MEASUREMENT = config.locale.formats;
                    LC_MONETARY = config.locale.formats;
                    LC_NAME = config.locale.formats;
                    LC_NUMERIC = config.locale.formats;
                    LC_PAPER = config.locale.formats;
                    LC_TELEPHONE = config.locale.formats;
                    LC_TIME = config.locale.formats;
                };

                environment.variables."XKB_DEFAULT_LAYOUT" = config.locale.keyboard-layout;
            };
        };
}
