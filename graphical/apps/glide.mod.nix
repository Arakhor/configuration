{ glide-browser, ... }:
{
    graphical =
        {
            pkgs,
            config,
            lib,
            ...
        }:
        let
            prefs = {
                "browser.startup.homepage" = "https://kagi.com/";

                "browser.aboutConfig.showWarning" = false;
                "browser.download.useDownloadDir" = false;
                "browser.toolbars.bookmarks.visibility" = "never";
                "browser.uidensity" = 1;
                "browser.urlbar.suggest.engines" = false;
                "browser.urlbar.suggest.openpage" = false;
                "devtools.debugger.prompt-connection" = false;
                "doms.forms.autocomplete.formautofill" = false;
                "extensions.formautofill.creditCards.enabled" = false;
                "layout.word_select.eat_space_to_next_word" = false;
                "media.videocontrols.picture-in-picture.audio-toggle.enabled" = true;
                "signon.management.page.breach-alerts.enabled" = false;
                "signon.rememberSignons" = false;
                "media.ffmpeg.vaapi.enabled" = true;

                "ui.key.menuAccessKeyFocuses" = false;
                "sidebar.main.tools" = "";
                "sidebar.revamp" = true;
                "sidebar.verticalTabs" = true;
            };

            extensions = [
                "canvasblocker"
                "clearurls"
                "dearrow"
                "istilldontcareaboutcookies"
                "kagi-search-for-firefox"
                "languagetool"
                "proton-pass"
                "refined-github-"
                "sponsorblock"
                "ublock-origin"
            ];

            css = # css
                ''
                    * {
                        font-family: ${config.style.fonts.sansSerif.name} !important;
                        font-size: 15px !important;
                    }
                '';

            renderPrefs =
                prefs:
                lib.concatMapStringsSep "\n" (k: "glide.prefs.set(\"${k}\", ${builtins.toJSON prefs.${k}});") (
                    lib.sort lib.lessThan (lib.attrNames prefs)
                );

            renderExtensions =
                extensions:
                lib.concatMapStringsSep "\n" (
                    slug:
                    "glide.addons.install(\"https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi\");"
                ) extensions;

            renderCss = css: ''
                glide.styles.add(css`
                    ${css}
                `);
            '';

        in
        {
            nixpkgs.overlays = [
                glide-browser.overlays.default
            ];

            wrappers.glide-browser =
                let
                    systemctl = lib.getExe' pkgs.systemd "systemctl";
                    notifySend = lib.getExe pkgs.libnotify;
                in
                {
                    basePackage = pkgs.glide-browser;
                    overrideAttrs = old: {
                        buildCommand = ''
                            ${old.buildCommand}
                            wrapProgram $out/bin/glide-browser \
                              --set MESA_SHADER_CACHE_DIR "/home/arakhor/.config/glide/glide/.cache" \
                              --run "${systemctl} is-active --quiet --user glide-browser-persist-init \
                                  || { ${notifySend} -e -u critical -t 3000 'Glide Browser' 'Initial sync has not yet finished'; exit 0; }"
                        '';
                    };
                };

            maid-users = {
                # Use systemd to synchronise Glide Browser data with persistent storage. Allows for
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
                        persistDir = "/state/home/arakhor/.config/glide/glide/";
                        tmpfsDir = "/home/arakhor/.config/glide/glide/";

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
                        services.glide-browser-persist-init = {
                            unitConfig = {
                                Description = "Glide Browser persist initialiser";
                                X-SwitchMethod = "keep-old";
                                # We don't want graphical-session.target activation to be delayed
                                # until this service is active.
                                After = [ "graphical-session.target" ];
                                PartOf = [ "graphical-session.target" ];
                                Requisite = [ "graphical-session.target" ];
                            };

                            serviceConfig = {
                                Type = "oneshot";
                                Slice = config.lib.session.appSlice;
                                ExecStart =
                                    (pkgs.writeShellScript "glide-browser-persist-init" # bash
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

                        services.glide-browser-persist-sync = {
                            unitConfig = {
                                Description = "Glide Browser persist synchroniser";
                                X-SwitchMethod = "keep-old";
                                After = [ "glide-browser-persist-init.service" ];
                                Requires = [ "glide-browser-persist-init.service" ];
                                Requisite = [ "graphical-session.target" ];
                            };

                            serviceConfig = {
                                Type = "oneshot";
                                Slice = config.lib.session.backgroundSlice;
                                CPUSchedulingPolicy = "idle";
                                # Sleep in an attempt to mitigate EXT4 file system corruption when resuming from hibernation
                                ExecStartPre = "${lib.getExe' pkgs.coreutils "sleep"} 30";
                                IOSchedulingClass = "idle";
                                ExecStart =
                                    (pkgs.writeShellScript "glide-persist-sync" ''
                                        ${syncToPersist}
                                    '').outPath;
                            };
                        };

                        timers.glide-browser-persist-sync = {
                            unitConfig = {
                                Description = "Glide Browser persist synchroniser timer";
                                X-SwitchMethod = "keep-old";
                                PartOf = [ "graphical-session.target" ];
                            };

                            timerConfig = {
                                OnCalendar = "*:0/30";
                            };

                            wantedBy = [ "graphical-session.target" ];
                        };
                    };

                file.xdg_config."glide/glide.ts".text = lib.concatLines [
                    (renderPrefs prefs)
                    (renderExtensions extensions)
                    (renderCss css)
                ];
            };

            programs.niri.settings.binds = with config.lib.niri.actions; {
                "Mod+B".action = spawn-sh "app2unit -t service glide-browser-bin.desktop";
            };
        };
}
