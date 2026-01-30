{
    cachyos-kernel,
    sources,
    naersk,
    ...
}:
{
    universal =
        {
            pkgs,
            # config,
            lib,
            ...
        }:
        {

            nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
            nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

            nixpkgs.overlays = [
                cachyos-kernel.overlays.pinned
                (
                    final: prev:
                    let
                        naersk' = final.callPackage naersk { };
                    in
                    {
                        scx_loader = naersk'.buildPackage {
                            src = sources.scx-loader;
                            postInstall = ''
                                substituteInPlace services/scx_loader.service \
                                  --replace "/usr/bin/scx_loader" "$out/bin/scx_loader"
                                substituteInPlace services/org.scx.Loader.service \
                                  --replace "/usr/bin/scx_loader" "$out/bin/scx_loader"

                                # Install the files
                                install -Dm644 services/scx_loader.service -t $out/lib/systemd/system/
                                install -Dm644 services/org.scx.Loader.service -t $out/share/dbus-1/system-services/
                                install -Dm644 configs/org.scx.Loader.conf -t $out/share/dbus-1/system.d/
                                install -Dm644 configs/org.scx.Loader.xml -t $out/share/dbus-1/interfaces/
                                install -Dm644 configs/org.scx.Loader.policy -t $out/share/polkit-1/actions/
                                install -Dm644 configs/scx_loader.toml $out/share/scx_loader/config.toml
                            '';
                        };
                        scx_tools = final.symlinkJoin {
                            name = "scx_tools";
                            paths = [
                                final.scx_loader
                                final.scx.full
                            ];
                        };
                    }
                )
            ];

            # boot.kernelPackages = pkgs.cachyosKernels.linux-cachyos-latest-lto;

            # boot.kernelPackages =
            #     pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto.override {
            #         autofdo = true; # https://cachyos.org/blog/2411-kernel-autofdo/
            #     }
            #     |> pkgs.linuxKernel.packagesFor
            #     |> lib.mkDefault;

            # https://wiki.cachyos.org/configuration/sched-ext/#tab-panel-64
            environment.systemPackages = [ pkgs.scx_tools ];
            services.dbus.packages = [ pkgs.scx_tools ];

            systemd.services.scx-loader = {
                description = "DBUS on-demand loader of sched-ext schedulers";

                unitConfig.ConditionPathIsDirectory = "/sys/kernel/sched_ext";

                serviceConfig = {
                    Type = "dbus";
                    BusName = "org.scx.Loader";
                    ExecStart = lib.getExe' pkgs.scx_tools "scx_loader";
                };

                path = [ pkgs.scx_tools ];

                wantedBy = [ "multi-user.target" ];
            };

            environment.etc."scx_loader.toml".source = (pkgs.formats.toml { }).generate "scx_loader.toml" {
                default_sched = "scx_cosmos";
                default_mode = "LowLatency";
                scheds.scx_cosmos = {
                    auto_mode = [
                        "-s"
                        "20000"
                        "-d"
                        "-c"
                        "0"
                        "-p"
                        "0"
                    ];
                    gaming_mode = [
                        "-c"
                        "0"
                        "-p"
                        "0"
                    ];
                    lowlatency_mode = [
                        "-m"
                        "performance"
                        "-c"
                        "0"
                        "-p"
                        "0"
                        "-w"
                    ];
                    powersave_mode = [
                        "-m"
                        "powersave"
                        "-d"
                        "-p"
                        "5000"
                    ];
                    server_mode = [
                        "-s"
                        "20000"
                    ];
                };
            };

            # https://wiki.cachyos.org/configuration/general_system_tweaks/#adios-io-scheduler
            hardware.block.scheduler = {
                "sd[a-z]*" = "bfq";
                "sd[a-z]*|mmcblk[0-9]*" = "adios";
                "nvme[0-9]*" = "adios";
            };

            boot.kernel.sysctl = {
                # The sysctl swappiness parameter determines the kernel's preference for pushing anonymous pages or page cache to disk in memory-starved situations.
                # A low value causes the kernel to prefer freeing up open files (page cache), a high value causes the kernel to try to use swap space,
                # and a value of 100 means IO cost is assumed to be equal.
                "vm.swappiness" = 100;

                # The value controls the tendency of the kernel to reclaim the memory which is used for caching of directory and inode objects (VFS cache).
                # Lowering it from the default value of 100 makes the kernel less inclined to reclaim VFS cache (do not set it to 0, this may produce out-of-memory conditions)
                "vm.vfs_cache_pressure" = 50;

                # Contains, as bytes, the number of pages at which a process which is
                # generating disk writes will itself start writing out dirty data.
                "vm.dirty_bytes" = 268435456;

                # page-cluster controls the number of pages up to which consecutive pages are read in from swap in a single attempt.
                # This is the swap counterpart to page cache readahead. The mentioned consecutivity is not in terms of virtual/physical addresses,
                # but consecutive on swap space - that means they were swapped out together. (Default is 3)
                # increase this value to 1 or 2 if you are using physical swap (1 if ssd, 2 if hdd)
                "vm.page-cluster" = 0;

                # Contains, as bytes, the number of pages at which the background kernel
                # flusher threads will start writing out dirty data.
                "vm.dirty_background_bytes" = 67108864;

                # The kernel flusher threads will periodically wake up and write old data out to disk.  This
                # tunable expresses the interval between those wakeups, in 100'ths of a second (Default is 500).
                "vm.dirty_writeback_centisecs" = 1500;

                # This action will speed up your boot and shutdown, because one less module is loaded. Additionally disabling watchdog timers increases performance and lowers power consumption
                # Disable NMI watchdog
                "kernel.nmi_watchdog" = 0;

                # Enable the sysctl setting kernel.unprivileged_userns_clone to allow normal users to run unprivileged containers.
                "kernel.unprivileged_userns_clone" = 1;

                # To hide any kernel messages from the console
                "kernel.printk" = "3 3 3 3";

                # Restricting access to kernel pointers in the proc filesystem
                "kernel.kptr_restrict" = 2;

                # Increase netdev receive queue
                # May help prevent losing packets
                "net.core.netdev_max_backlog" = 4096;

                # Set size of file handles and inode cache
                "fs.file-max" = 2097152;
            };

            services.earlyoom = {
                enable = lib.mkDefault true;
                extraArgs = lib.mkDefault [
                    "-M"
                    "409600,307200"
                    "-S"
                    "409600,307200"
                ];
            };

            zramSwap = {
                enable = true;
                algorithm = "zstd";
                memoryPercent = 100;
                priority = 100;
            };

            services.udev.extraRules = ''
                # When used with ZRAM, it is better to prefer page out only anonymous pages,
                # because it ensures that they do not go out of memory, but will be just
                # compressed. If we do frequent flushing of file pages, that increases the
                # percentage of page cache misses, which in the long term gives additional
                # cycles to re-read the same data from disk that was previously in page cache.
                # This is the reason why it is recommended to use high values from 100 to keep
                # the page cache as hermetic as possible, because otherwise it is "expensive"
                # to read data from disk again. At the same time, uncompressing pages from ZRAM
                # is not as expensive and is usually very fast on modern CPUs.
                #
                # Also it's better to disable Zswap, as this may prevent ZRAM from working
                # properly or keeping a proper count of compressed pages via zramctl.
                ACTION=="change", KERNEL=="zram0", ATTR{initstate}=="1", SYSCTL{vm.swappiness}="150", \
                    RUN+="/bin/sh -c 'echo N > /sys/module/zswap/parameters/enabled'"

                # Allows access to rtc0 and hpet device nodes by the audio group
                KERNEL=="rtc0", GROUP="audio"
                KERNEL=="hpet", GROUP="audio"

                # Allows access to the cpu_dma_latency device node by the audio group
                DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
            '';

            systemd.settings.Manager = {
                # Faster shutdown without breaking startup
                DefaultTimeoutStopSec = 10;

                # High per-process file descriptor limit (soft = hard)
                DefaultLimitNOFILE = 2097152;
            };
        };
}
