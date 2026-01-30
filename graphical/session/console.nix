# based on https://github.com/NixOS/nixpkgs/pull/391574
let
    libtsmPackage =
        {
            lib,
            stdenv,
            fetchFromGitHub,
            libxkbcommon,
            pkg-config,
            meson,
            ninja,
            check,
        }:
        stdenv.mkDerivation (finalAttrs: {
            pname = "libtsm";
            version = "4.3.0-unstable-2025-12-23";

            src = fetchFromGitHub {
                owner = "kmscon";
                repo = "libtsm";
                rev = "10a34a5b7b5fe2d7c1398134400812d69d9c2432";
                hash = "sha256-PcY10Zh6NelZtwBhzRdvVq9sW7LdWsfP0Ta8OW4Wls8=";
            };

            buildInputs = [ libxkbcommon ];

            nativeBuildInputs = [
                meson
                ninja
                check
                pkg-config
            ];

            meta = {
                description = "Terminal-emulator State Machine";
                homepage = "https://www.freedesktop.org/wiki/Software/kmscon/libtsm/";
                license = lib.licenses.mit;
                maintainers = with lib.maintainers; [ hustlerone ];
                platforms = lib.platforms.linux;
            };
        });

    kmsconPackage =
        {
            lib,
            stdenv,
            fetchFromGitHub,
            fetchpatch,
            meson,
            libtsm,
            systemdLibs,
            libxkbcommon,
            libdrm,
            libGLU,
            libGL,
            pango,
            bash,
            shadow,
            pkg-config,
            docbook_xsl,
            libxslt,
            libgbm,
            ninja,
            check,
            buildPackages,
        }:
        stdenv.mkDerivation (finalAttrs: {
            pname = "kmscon";
            version = "9.2.1-unstable-2026-01-09";

            src = fetchFromGitHub {
                owner = "kmscon";
                repo = "kmscon";
                rev = "d45bc8b2b48497237f620c2ed5d07a0774e495d1";
                hash = "sha256-dMUp0nlf5O7jIp7Eeruo0z+geVpDpOxsqt76rrbP6/w=";
            };

            strictDeps = true;

            depsBuildBuild = [
                buildPackages.stdenv.cc
            ];

            buildInputs = [
                libGLU
                libGL
                libdrm
                libtsm
                libxkbcommon
                pango
                systemdLibs
                libgbm
                check
                bash
            ];

            nativeBuildInputs = [
                meson
                ninja
                docbook_xsl
                pkg-config
                libxslt # xsltproc
            ];

            env.NIX_CFLAGS_COMPILE =
                lib.optionalString stdenv.cc.isGNU "-O "
                + "-Wno-error=maybe-uninitialized -Wno-error=unused-result -Wno-error=implicit-function-declaration";

            enableParallelBuilding = true;

            patches = [
                ./sandbox.patch # Generate system units where they should be (nix store) instead of /etc/systemd/system
            ];

            postPatch = ''
                substituteInPlace src/pty.c src/kmscon_conf.c docs/man/kmscon.1.xml.in \
                --replace-fail /bin/login ${lib.getExe' shadow "login"}
            '';

            meta = {
                description = "KMS/DRM based System Console";
                mainProgram = "kmscon";
                homepage = "https://www.freedesktop.org/wiki/Software/kmscon/";
                license = lib.licenses.mit;
                maintainers = with lib.maintainers; [ hustlerone ];
                platforms = lib.platforms.linux;
            };
        });
in
{
    graphical =
        {
            config,
            pkgs,
            lib,
            ...
        }:
        let
            cfg = config.services.kmscon;
            gcfg = config.services.getty;

        in
        {
            nixpkgs.overlays = [
                (final: prev: {
                    libtsm = final.callPackage libtsmPackage { };
                    kmscon = final.callPackage kmsconPackage { };
                })
            ];

            environment.systemPackages = [ cfg.package ];

            services.kmscon = {
                enable = false;
                useXkbConfig = true;
                hwRender = true;
                fonts = [
                    { inherit (config.style.fonts.monospace) name package; }
                    {
                        name = "Symbols Nerd Font";
                        package = pkgs.nerd-fonts.symbols-only;
                    }
                ];
                extraOptions = "--term xterm-256color";
                extraConfig =
                    let
                        xkb = lib.optionals cfg.useXkbConfig (
                            lib.mapAttrsToList (n: v: "xkb-${n}=${v}") (
                                lib.filterAttrs (
                                    n: v:
                                    builtins.elem n [
                                        "layout"
                                        "model"
                                        "options"
                                        "variant"
                                    ]
                                    && v != ""
                                ) config.services.xserver.xkb
                            )
                        );
                        render = lib.optionals cfg.hwRender [
                            "drm"
                            "hwaccel"
                        ];
                        fonts =
                            lib.optional (cfg.fonts != null)
                                "font-name=${lib.concatMapStringsSep ", " (f: f.name) cfg.fonts}";
                        extra = [
                            "font-size=24"
                            "xkb-layout=${config.locale.keyboard-layout}"
                        ];
                    in
                    lib.concatLines (xkb ++ render ++ fonts ++ extra);
            };

            systemd = {
                packages = [ cfg.package ];
                services."kmsconvt@" = {
                    description = "KMS System Console on %I";
                    documentation = [ "man:kmscon(1)" ];
                    before = [ "getty.target" ];
                    after = [
                        "systemd-user-sessions.service"
                        "plymouth-quit-wait.service"
                        "rc-local.service"
                    ];
                    conflicts = [ "getty@%i.service" ];
                    onFailure = [ "getty@%i.service" ];
                    wantedBy = [ "getty.target" ];
                    unitConfig = {
                        IgnoreOnIsolate = "yes";
                        ConditionPathExists = "/dev/tty0";
                    };
                    serviceConfig =
                        let
                            configDir = pkgs.writeTextFile {
                                name = "kmscon-config";
                                destination = "/kmscon.conf";
                                text = cfg.extraConfig;
                            };

                            baseArgs = [
                                "--login-program"
                                "${gcfg.loginProgram}"
                            ]
                            ++ lib.optionals (gcfg.autologinUser != null && !gcfg.autologinOnce) [
                                "--autologin"
                                gcfg.autologinUser
                            ]
                            ++ lib.optionals (gcfg.loginOptions != null) [
                                "--login-options"
                                gcfg.loginOptions
                            ]
                            ++ gcfg.extraArgs;

                            gettyCmd = "${lib.getExe' pkgs.util-linux "agetty"} ${lib.escapeShellArgs baseArgs} --noclear - -- $$TERM";
                        in
                        {
                            ExecStart = "${pkgs.kmscon}/bin/kmscon --vt=%I --seats=seat0 --no-switchvt ${
                                lib.optionalString (!cfg.hwRender) "--no-drm"
                            } --configdir ${configDir} --login -- ${gettyCmd}";

                            ## I know that usually we'd be using /bin/login directly, but this is what upstream's doing.

                            UtmpIdentifier = "%I";
                            TTYPath = "/dev/%I";
                            TTYReset = true;
                            TTYVHangup = true;
                            TTYVTDisallocate = true;
                        };

                    restartIfChanged = false;
                    aliases = [ "autovt@.service" ];
                };

                suppressedSystemUnits = [ "autovt@.service" ];

                services.systemd-vconsole-setup.enable = false;
                services.reload-systemd-vconsole-setup.enable = false;
            };
        };
}
