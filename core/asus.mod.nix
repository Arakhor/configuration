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
                kernelPackages = lib.mkForce pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-zen4;

                # kernelPackages =
                #     pkgs.cachyosKernels.linux-cachyos-latest-lto-zen4.override {
                #         autofdo = true;

                #         # patches = map (v: sources.linux-g14 + "/" + v + ".patch") [
                #         #     "PATCH-asus-wmi-fixup-screenpad-brightness"
                #         #     "0010-platform-x86-asus-wmi-move-keyboard-control-firmware"
                #         # ];
                #     }
                #     |> pkgs.linuxKernel.packagesFor
                #     |> lib.mkForce;

                kernelParams = [
                    "amdgpu.sg_display=0"
                ];

                extraModprobeConfig = ''
                    NVreg_UsePageAttributeTable=1
                    NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100
                '';
            };

            services.asusd.enable = true;
            systemd.services.asusd.wantedBy = [ "multi-user.target" ];

            # Broken
            services.asusd.enableUserService = lib.mkForce false;
            services.supergfxd.enable = lib.mkForce false;

            # services.switcherooControl.enable = true;

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
                "nvidia"
                "amdgpu"
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
                        "dri/by-path/pci-${domain}:${busHex}:${deviceHex}.${function}";

                    pCfg = config.hardware.nvidia.prime;

                    # Determine IGPU path based on whether intel or amdgpu bus ID is set
                    igpuBusId = if pCfg.intelBusId != "" then pCfg.intelBusId else pCfg.amdgpuBusId;
                    dgpuBusId = pCfg.nvidiaBusId;

                in
                lib.singleton (
                    pkgs.writeTextDir "lib/udev/rules.d/61-gpu-offload.rules" ''
                        SYMLINK=="${pciPath igpuBusId}-card", SYMLINK+="dri/igpu-card"
                        SYMLINK=="${pciPath igpuBusId}-render", SYMLINK+="dri/igpu-render"
                        SYMLINK=="${pciPath dgpuBusId}-card", SYMLINK+="dri/dgpu-card"
                        SYMLINK=="${pciPath dgpuBusId}-render", SYMLINK+="dri/dgpu-render"
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

            programs.nushell.shellAliases = {
                miniled = "asusctl armoury set mini_led_mode";
                aura = "asusctl aura effect";
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
