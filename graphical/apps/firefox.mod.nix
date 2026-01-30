{ sources, ... }:
{
    graphical =
        {
            pkgs,
            config,
            lib,
            ...
        }:
        {
            wrappers.firefox =
                let
                    systemctl = lib.getExe' pkgs.systemd "systemctl";
                    notifySend = lib.getExe pkgs.libnotify;
                in
                {
                    basePackage = pkgs.firefox;
                    overrideAttrs = old: {
                        buildCommand = ''
                            ${old.buildCommand}
                            wrapProgram $out/bin/firefox \
                              --run "${systemctl} is-active --quiet --user firefox-persist-init \
                                  || { ${notifySend} -e -u critical -t 3000 'Firefox' 'Initial sync has not yet finished'; exit 0; }"
                        '';
                    };
                };

            maid-users = {
                # Use systemd to synchronise firefox data with persistent storage. Allows for
                # running  on tmpfs with improved performance.

                # Ideally we would make the sync service a strict dependency of
                # graphical-session.target to ensure that firefox cannot be launched before
                # the sync has finished (if firefox launches it creates files and breaks
                # the sync). However, I don't want graphical-session.target to be delayed
                # ~10 secs every boot until the sync finishes. Instead, I wrap the firefox
                # package to prevent launch unless sync has finished. That way I can use
                # other applications until firefox is ready.
                systemd =
                    let
                        rsync = lib.getExe pkgs.rsync;
                        fd = lib.getExe pkgs.fd;
                        persistDir = "/state${tmpfsDir}";
                        tmpfsDir = "/home/arakhor/.config/mozilla/";

                        syncToTmpfs = # bash
                            ''
                                # Do not delete the existing Nix store links when syncing
                                ${fd} -Ht l --base-directory "${tmpfsDir}" | \
                                  ${rsync} -ah --no-links --delete --info=stats1 \
                                  --exclude-from=- "${persistDir}" "${tmpfsDir}"
                            '';

                        syncToPersist = # bash
                            ''
                                ${rsync} -ah --no-links --delete --info=stats1 \
                                  "${tmpfsDir}" "${persistDir}"
                            '';
                    in
                    {
                        services.firefox-persist-init = {
                            description = "Firefox persist initialiser";
                            after = [ "graphical-session.target" ];
                            partOf = [ "graphical-session.target" ];
                            requisite = [ "graphical-session.target" ];
                            unitConfig.X-SwitchMethod = "keep-old";

                            serviceConfig = {
                                Type = "oneshot";
                                Slice = config.lib.session.appSlice;
                                ExecStart =
                                    (pkgs.writeShellScript "firefox-persist-init" # bash
                                        ''
                                            if [ ! -e "${persistDir}" ]; then
                                              ${syncToPersist}
                                            else
                                              ${syncToTmpfs}
                                            fi
                                        ''
                                    ).outPath;
                                # Backup on shutdown
                                ExecStop = syncToPersist;
                                RemainAfterExit = true;
                            };

                            wantedBy = [ "graphical-session.target" ];
                        };

                        services.firefox-persist-sync = {
                            description = "Firefox persist synchroniser";
                            after = [ "firefox-persist-init.service" ];
                            requires = [ "firefox-persist-init.service" ];
                            requisite = [ "graphical-session.target" ];
                            unitConfig.X-SwitchMethod = "keep-old";

                            serviceConfig = {
                                Type = "oneshot";
                                Slice = config.lib.session.backgroundSlice;
                                CPUSchedulingPolicy = "idle";
                                # Sleep in an attempt to mitigate EXT4 file system corruption when resuming from hibernation
                                ExecStartPre = "${lib.getExe' pkgs.coreutils "sleep"} 30";
                                IOSchedulingClass = "idle";
                                ExecStart =
                                    (pkgs.writeShellScript "firefox-persist-sync" ''
                                        ${syncToPersist}
                                    '').outPath;
                            };
                        };

                        timers.firefox-persist-sync = {
                            description = "Firefox persist synchroniser timer";
                            partOf = [ "graphical-session.target" ];
                            unitConfig.X-SwitchMethod = "keep-old";

                            timerConfig.OnCalendar = "*:0/30";

                            wantedBy = [ "graphical-session.target" ];
                        };
                    };

                file.xdg_config = {
                    "mozilla/firefox/profiles.ini".text = /* ini */ ''
                        [Profile0]
                        Name=default
                        IsRelative=1
                        Path=default
                        Default=1

                        [General]
                        StartWithLastProfile=1
                        Version=2
                    '';
                    "mozilla/firefox/default/user.js".text = /* js */ ''
                        // Enable customChrome.css
                        user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

                        // Set UI density to normal
                        user_pref("browser.uidensity", 0);

                        // Enable SVG context-propertes
                        user_pref("svg.context-properties.content.enabled", true);

                        // Disable private window dark theme
                        user_pref("browser.theme.dark-private-windows", false);

                        // Enable rounded bottom window corners
                        user_pref("widget.gtk.rounded-bottom-corners.enabled", true);
                    '';
                    "mozilla/firefox/default/chrome/userChrome.css".text = /* css */ ''
                        @import "${sources.firefox-gnome-theme}/userChrome.css";
                        * {
                            font-family: ${config.style.fonts.sansSerif.name} !important;
                            font-size: 15px !important;
                        }
                    '';
                    "mozilla/firefox/default/chrome/userContent.css".text = /* css */ ''
                        @import "${sources.firefox-gnome-theme}/userContent.css";
                    '';
                };
            };

            # programs.niri.settings.binds = with config.lib.niri.actions; {
            #     "Mod+B".action = spawn-sh "app2unit -t service firefox.desktop";
            # };
        };
}
