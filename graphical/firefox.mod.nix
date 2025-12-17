{
  graphical.home =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      packages = [
        (pkgs.firefox.overrideAttrs (old: {
          buildCommand =
            let
              systemctl = lib.getExe' pkgs.systemd "systemctl";
              notifySend = lib.getExe pkgs.libnotify;
            in
            # Setting MESA_SHADER_CACHE_DIR here fixes the following log spam:
            # Failed to create /home/arakhor/.cache for shader cache (Permission denied)---disabling.
            # I've got no idea why firefox can't access ~/.cache
            # Same issue but with flatpak: https://github.com/zen-browser/desktop/issues/2767
            # bash
            ''
              ${old.buildCommand}
              wrapProgram $out/bin/firefox \
                --set MESA_SHADER_CACHE_DIR "/home/arakhor/.mozilla/.cache" \
                --run "${systemctl} is-active --quiet --user firefox-persist-init \
                || { ${notifySend} -e -u critical -t 3000 'Firefox' 'Initial sync has not yet finished'; exit 0; }"
            '';
        }))
      ];

      systemd =
        let
          rsync = lib.getExe pkgs.rsync;
          fd = lib.getExe pkgs.fd;
          persistDir = "/persist/home/arakhor/.mozilla/";
          tmpfsDir = "/home/arakhor/.mozilla/";

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
            unitConfig.X-SwitchMethod = "keep-old";

            # We don't want graphical-session.target activation to be delayed
            # until this service is active.
            after = [ "graphical-session.target" ];
            partOf = [ "graphical-session.target" ];
            requisite = [ "graphical-session.target" ];

            serviceConfig = {
              Type = "oneshot";
              Slice = "app.slice";
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
            unitConfig.X-SwitchMethod = "keep-old";

            after = [ "firefox-persist-init.service" ];
            requires = [ "firefox-persist-init.service" ];
            requisite = [ "graphical-session.target" ];

            serviceConfig = {
              Type = "oneshot";
              Slice = "background-graphical.slice";
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

            unitConfig = {
              X-SwitchMethod = "keep-old";

            };

            partOf = [ "graphical-session.target" ];

            timerConfig.OnCalendar = "*:0/30";

            wantedBy = [ "graphical-session.target" ];
          };
        };

      programs.niri.settings.binds = with config.lib.niri.actions; {
        "Mod+B".action = spawn-sh "firefox";
      };
    };
}
