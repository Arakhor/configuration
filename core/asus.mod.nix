{ sources, ... }:
{
    zeph =
        {
            pkgs,
            config,
            lib,
            ...
        }:
        {
            boot = {
                # kernelPackages = lib.mkForce pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-zen4;

                kernelPackages =
                    pkgs.cachyosKernels.linux-cachyos-latest-lto-zen4.override {
                        autofdo = true;

                        patches = map (v: sources.linux-g14 + "/" + v + ".patch") [
                            "PATCH-asus-wmi-fixup-screenpad-brightness"
                            "0010-platform-x86-asus-wmi-move-keyboard-control-firmware"
                        ];
                    }
                    |> pkgs.linuxKernel.packagesFor
                    |> lib.mkForce;

                initrd.kernelModules = [
                    "amdgpu"
                    # "nvidia"
                    # "nvidia_modeset"
                    # "nvidia_uvm"
                    # "nvidia_drm"
                ];

                kernelParams = [
                    "amdgpu.sg_display=0"
                ];

                extraModprobeConfig = ''
                    NVreg_UsePageAttributeTable=1
                    NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100
                '';
            };

            nixpkgs.overlays = [
                (final: prev: {
                    asusctl = prev.rustPlatform.buildRustPackage rec {
                        pname = "asusctl";
                        # Set this to the version from your source or desired tag
                        version = sources.asusctl.version;
                        src = sources.asusctl;

                        # Set to empty string to get the correct hash on the first build
                        cargoHash = "sha256-FlEuv/iaNlfXLhHRSmZedPwroCozaEqIvYRqbgJhgEw=";

                        env = {
                            # force linking to all the dlopen()ed dependencies
                            RUSTFLAGS = toString (
                                map (a: "-C link-arg=${a}") [
                                    "-Wl,--push-state,--no-as-needed"
                                    "-lEGL"
                                    "-lfontconfig"
                                    "-lwayland-client"
                                    "-Wl,--pop-state"
                                ]
                            );
                        };

                        # Inherit standard build attributes
                        inherit (prev.asusctl)
                            nativeBuildInputs
                            buildInputs
                            meta
                            doCheck
                            doInstallCheck
                            ;

                        # Copy postPatch from the package definition.
                        # Note: If the 'sg' crate version in your Cargo.lock differs
                        # from '0.4.0', you may need to update that path below.
                        postPatch = ''
                            files="asusd-user/src/config.rs asusd-user/src/daemon.rs asusd/src/aura_anime/config.rs rog-aura/src/aura_detection.rs rog-control-center/src/lib.rs rog-control-center/src/main.rs rog-control-center/src/tray.rs"
                            for file in $files; do
                              substituteInPlace $file --replace-fail /usr/share $out/share
                            done

                            substituteInPlace rog-control-center/src/main.rs \
                              --replace-fail 'std::env::var("RUST_TRANSLATIONS").is_ok()' 'true'

                            substituteInPlace data/asusd.service \
                              --replace-fail /usr/bin/asusd $out/bin/asusd \
                              --replace-fail /bin/sleep ${prev.lib.getExe' prev.coreutils "sleep"}
                            substituteInPlace data/asusd-user.service \
                              --replace-fail /usr/bin/asusd-user $out/bin/asusd-user \
                              --replace-fail /usr/bin/sleep ${prev.lib.getExe' prev.coreutils "sleep"}

                            substituteInPlace Makefile \
                              --replace-fail /usr/bin/grep ${prev.lib.getExe prev.gnugrep}

                            substituteInPlace /build/asusctl-''${version}-vendor/sg-0.4.0/build.rs \
                              --replace-fail /usr/include ${prev.lib.getDev prev.glibc}/include
                        '';

                        # Copy postInstall
                        postInstall = ''
                            make prefix=$out install-data

                            patchelf $out/bin/rog-control-center \
                              --add-needed ${prev.lib.getLib prev.libxkbcommon}/lib/libxkbcommon.so.0
                        '';
                    };
                })
            ];

            services.asusd.enable = true;
            systemd.services.asusd.wantedBy = [ "multi-user.target" ];
            services.asusd.enableUserService = lib.mkForce false;
            services.supergfxd.enable = lib.mkForce false;
            services.switcherooControl.enable = true;

            hardware.graphics = {
                enable = true;
                enable32Bit = true;
                extraPackages = with pkgs; [
                    libva-vdpau-driver
                    nvidia-vaapi-driver
                ];
                extraPackages32 = with pkgs.pkgsi686Linux; [ nvidia-vaapi-driver ];
            };

            services.xserver.videoDrivers = [
                "amdgpu"
                "nvidia"
            ];

            # Set up a udev rule to create named symlinks for the pci paths.
            services.udev.packages =
                let
                    # Parse a BusID string formatted like "PCI:9@0:0:0" into a PCI path.
                    # Expected format: PCI:<bus>@<device>:<function>
                    # Note: The <domain> is usually omitted and assumed to be 0000.
                    pciPath =
                        xorgBusId:
                        let
                            # Remove the "PCI:" prefix
                            idStr = lib.removePrefix "PCI:" xorgBusId;

                            # Split on '@' to separate bus and device:function
                            parts = lib.splitString "@" idStr;
                            bus = builtins.elemAt parts 0;

                            # Split the second part on ':' to separate device and function
                            devFuncParts = lib.splitString ":" (builtins.elemAt parts 1);
                            device = builtins.elemAt devFuncParts 0;
                            function = builtins.elemAt devFuncParts 1;

                            # Helper to format numbers as padded hex strings
                            toHex = i: lib.toLower (lib.toHexString (lib.toInt i));

                            domain = "0000";
                            busHex = lib.fixedWidthString 2 "0" (toHex bus);
                            deviceHex = lib.fixedWidthString 2 "0" (toHex device);
                        in
                        "dri/by-path/pci-${domain}:${busHex}:${deviceHex}.${function}-render";

                    pCfg = config.hardware.nvidia.prime;

                    # Determine IGPU path based on whether intel or amdgpu bus ID is set
                    igpuBusId = if pCfg.intelBusId != "" then pCfg.intelBusId else pCfg.amdgpuBusId;
                    dgpuBusId = pCfg.nvidiaBusId;

                in
                lib.singleton (
                    pkgs.writeTextDir "lib/udev/rules.d/61-gpu-offload.rules" ''
                        SYMLINK=="${pciPath igpuBusId}", SYMLINK+="dri/igpu"
                        SYMLINK=="${pciPath dgpuBusId}", SYMLINK+="dri/dgpu"
                    ''
                );

            hardware.nvidia = {
                package = config.boot.kernelPackages.nvidiaPackages.stable;
                open = true;

                nvidiaSettings = true;

                dynamicBoost.enable = true;
                modesetting.enable = true;
                powerManagement = {
                    enable = true;
                    finegrained = true;
                };

                prime = {
                    amdgpuBusId = "PCI:9@0:0:0";
                    nvidiaBusId = "PCI:1@0:0:0";
                    offload = {
                        enable = true;
                        enableOffloadCmd = true;
                    };
                };
            };

            environment.sessionVariables = {
                # GPU cache size limit (12GB)
                __GL_SHADER_DISK_CACHE_SIZE = 12000000000;
                # Set RADV as default Vulkan driver
                AMD_VULKAN_ICD = "RADV";
            };

            # Preserve critical configuration directories
            preserveSystem.directories = [
                "/etc/asusd"
            ];

            # Preserve user-specific GPU and ROG application data
            preserveHome.directories = [
                ".config/rog"
                ".cache/nvidia"
                ".cache/AMD"
            ];
        };
}
