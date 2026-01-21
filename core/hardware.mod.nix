{
    disko,
    cachyos-kernel,
    ...
}:
{
    universal =
        {
            lib,
            config,
            pkgs,
            ...
        }:

        # ====================
        # BASIC MODULES & OVERLAYS
        # ====================
        # Import Disko for declarative disk management
        # Apply CachyOS kernel overlays for performance optimizations
        {
            imports = [ disko.nixosModules.disko ];

            nixpkgs.overlays = [ cachyos-kernel.overlays.pinned ];
            nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
            nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

            # ====================
            # FIRMWARE & UPDATES
            # ====================
            #
            # Use latest CachyOS kernel with LTO and Zen4 optimizations
            boot.kernelPackages = lib.mkDefault pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto;

            # Enable fwupd for firmware updates across devices
            services.fwupd.enable = true;

            # ====================
            # POWER MANAGEMENT
            # ====================
            # Dynamic power settings based on system form factor
            # Only enable UPower on laptops
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

            # Ensure UPower starts with graphical session when enabled
            systemd.services.upower.wantedBy = lib.mkIf config.services.upower.enable [ "graphical.target" ];

            # Power Profiles Daemon for dynamic power profile switching
            services.power-profiles-daemon.enable = true;

            # ====================
            # HARDWARE SUPPORT
            # ====================
            # Enable support for gaming peripherals and input devices
            hardware.xpadneo.enable = true;
            hardware.i2c.enable = true;
            hardware.brillo.enable = true;
            hardware.steam-hardware.enable = true;

            # Bluetooth configuration
            services.blueman.enable = true;
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
                "video"
            ];

            # ====================
            # I/O SCHEDULER TUNING
            # ====================
            # CachyOS ADIOS scheduler for improved responsiveness
            # Applied selectively based on storage type
            # Reference: https://wiki.cachyos.org/configuration/general_system_tweaks/#adios-io-scheduler
            hardware.block.scheduler = {
                "sd[a-z]*" = "bfq";
                "sd[a-z]*|mmcblk[0-9]*" = "adios";
                "nvme[0-9]*" = "adios";
            };

            # ====================
            # STATE PRESERVATION
            # ====================
            # Preserve system state across updates/reboots
            preserveSystem.directories = [
                "/var/lib/power-profiles-daemon"
                "/var/lib/fwupd"
                "/var/lib/bluetooth"
            ];
        };

    # ===============
    # XPS CONFIGURATION
    # ===============
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

    # =================
    # ZEPH CONFIGURATION
    # =================
    zeph =
        {
            pkgs,
            config,
            lib,
            ...
        }:
        {
            networking.hostName = "zeph";
            hardware.facter.reportPath = ./hardware-scans/zeph.json;

            # Use latest CachyOS kernel with LTO and Zen4 optimizations
            boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-zen4;

            # ====================
            # ASUS-SPECIFIC SERVICES
            # ====================
            services.asusd.enable = true;
            services.asusd.enableUserService = true;
            programs.rog-control-center = {
                enable = true;
                autoStart = true;
            };

            # Ensure services start at appropriate runlevels
            systemd.services.asusd.wantedBy = [ "multi-user.target" ];
            systemd.user.services.asusd-user.wantedBy = [ "multi-user.target" ];

            # Disable supergfxd as it conflicts with current setup
            services.supergfxd.enable = lib.mkForce false;

            # ====================
            # GRAPHICS & GPU SETUP
            # ====================
            # System packages for GPU monitoring and testing
            environment.systemPackages = with pkgs; [
                nvtopPackages.amd
                nvtopPackages.nvidia
                mesa-demos
            ];

            # Enable graphics support with 32-bit compatibility
            hardware.graphics = {
                enable = true;
                enable32Bit = true;
                extraPackages = with pkgs; [
                    libva-vdpau-driver
                    nvidia-vaapi-driver
                ];
            };

            # Enable AMDGPU initrd support
            hardware.amdgpu.initrd.enable = true;

            # Set RADV as default Vulkan driver
            environment.sessionVariables.AMD_VULKAN_ICD = "RADV";

            services.xserver.videoDrivers = [
                "amdgpu"
                "nvidia"
            ];

            hardware.nvidia = {
                package = config.boot.kernelPackages.nvidiaPackages.latest;
                open = true;

                nvidiaSettings = false; # doesn't work on wayland

                dynamicBoost.enable = true;
                modesetting.enable = true;
                powerManagement = {
                    enable = true;
                    finegrained = true;
                };

                prime = {
                    amdgpuBusId = "PCI:9:0:0";
                    nvidiaBusId = "PCI:1:0:0";
                    offload = {
                        enable = true;
                        enableOffloadCmd = true;
                    };
                };
            };

            # GPU cache size limit (12GB)
            environment.sessionVariables = {
                __GL_SHADER_DISK_CACHE_SIZE = 12000000000;
            };

            # UDEV rules for NVIDIA device power management
            # - Remove unnecessary USB controllers
            # - Enable runtime power management on bind
            # - Disable runtime PM on unbind
            services.udev.extraRules = ''
                ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{remove}="1"
                ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{remove}="1"
                ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
                ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
                ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
                ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"
            '';

            # ====================
            # STATE PRESERVATION
            # ====================
            # Preserve critical configuration directories
            preserveSystem.directories = [
                {
                    directory = "/etc/asusd";
                    inInitrd = true;
                }
            ];

            # Preserve user-specific GPU and ROG application data
            preserveHome.directories = [
                ".config/rog"
                ".cache/nvidia"
                ".cache/AMD"
            ];
        };
}
