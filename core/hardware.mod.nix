{
  nixos-facter-modules,
  kernel-overlay,
  disko,
  ...
}:
{
  universal =
    { config, lib, ... }:
    {
      substituters = [ "https://kernel-overlay.cachix.org" ];
      trusted-public-keys = [
        "kernel-overlay.cachix.org-1:rUvSa2sHn0a7RmwJDqZvijlzZHKeGvmTQfOUr2kaxr4="
      ];

      imports = [
        disko.nixosModules.disko
        nixos-facter-modules.nixosModules.facter
      ];

      services.fwupd.enable = true;
      preserveSystem.directories = [ "/var/lib/fwupd" ];

      services.power-profiles-daemon.enable = true;

      services.upower = {
        enable = lib.mkDefault (config.facter.report.hardware.system.form_factor == "laptop");
        percentageLow = 15;
        percentageCritical = 5;
        percentageAction = 3;
      };
    };

  xps = {
    networking.hostName = "xps";
    facter.reportPath = ./hardware-scans/xps.json;
    services.fstrim.enable = true;
    systemd.tmpfiles.rules = [ "w /sys/power/image_size - - - - 0" ];
  };

  zeph =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      networking.hostName = "zeph";
      facter.reportPath = ./hardware-scans/zeph.json;

      boot.kernelPackages =
        kernel-overlay.packages.${pkgs.stdenv.buildPlatform.system}.linuxPackages_testing;

      boot.initrd.kernelModules = lib.mkBefore [ "amdgpu" ];

      services.xserver.videoDrivers = [
        "modesetting"
        "nvidia"
      ];

      hardware.nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        open = true;
        nvidiaSettings = false; # does not work on wayland
        powerManagement.enable = true;

        prime = {
          amdgpuBusId = "PCI:9:0:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          libva-vdpau-driver
          nvidia-vaapi-driver
        ];
      };

      services.asusd = {
        enable = true;
        enableUserService = true;
      };

      home.packages = [

        pkgs.amdgpu_top
        (lib.hiPrio (
          pkgs.runCommand "amdgpu_top-desktop-rename" { } ''
            mkdir -p $out/share/applications
            substitute ${pkgs.amdgpu_top}/share/applications/amdgpu_top.desktop $out/share/applications/amdgpu_top.desktop \
              --replace-fail "Name=AMDGPU TOP (GUI)" "Name=AMDGPU Top"
          ''
        ))
      ];

      environment.sessionVariables.AMD_VULKAN_ICD = "RADV";

      preserveHome.directories = [
        ".cache/nvidia"
        ".cache/AMD"
      ];
    };
}
