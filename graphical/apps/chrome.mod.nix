{ helium, ... }:
{
    graphical =
        { pkgs, lib, ... }:
        let
            commonFlags = [
                # Wayland support
                "--ozone-platform=wayland"
                "--enable-features=WaylandWindowDecorations"
                # GPU and Video Acceleration Flags
                # "--use-vulkan=native"
                # "--enable-dawn-backend=vulkan"
                "--ignore-gpu-blocklist"
                "--enable-gpu-rasterization"
                "--enable-zero-copy"
                "--enable-raw-draw"
                "--enable-drdc"
                "--disable-gpu-driver-bug-workarounds"
                "--disable-features=UseChromeOSDirectVideoDecoder"
                "--enable-features=${
                    lib.concatStringsSep "," [
                        "UseOzonePlatform"
                        # "Vulkan"
                        "SkiaGraphite"
                        "VaapiVideoEncoder"
                        "VaapiVideoDecoder"
                        "CanvasOopRasterization"
                        "VaapiIgnoreDriverChecks"
                        "OverlayScrollbar"
                        "ParallelDownloading"
                    ]
                }"
                # Performance
                "--enable-hardware-overlays"
                "--enable-accelerated-video-decode"
                "--enable-accelerated-video-encode"
                "--enable-accelerated-mjpeg-decode"
                "--enable-oop-rasterization"
                "--enable-webgl-developer-extensions"
                "--enable-accelerated-2d-canvas"
                "--enable-direct-composition"
                "--enable-gpu-compositing"
                # Smooth browsing
                "--enable-media-router"
                "--enable-smooth-scrolling"
                # UnGoogled features
                "--disable-search-engine-collection"
                "--extension-mime-request-handling=always-prompt-for-install"
                "--fingerprinting-canvas-image-data-noise"
                "--fingerprinting-canvas-measuretext-noise"
                "--fingerprinting-client-rects-noise"
                "--popups-to-tabs"
                "--force-punycode-hostnames"
                "--show-avatar-button=incognito-and-guest"
                # Miscellaneous
                "--no-default-browser-check"
                "--no-pings"
            ];

        in
        {
            preserveHome.directories = [
                ".config/google-chrome"
                ".config/net.imput.helium"
            ];

            wrappers = {
                google-chrome = {
                    basePackage = pkgs.google-chrome;
                    prependFlags = commonFlags;
                };

                helium = {
                    basePackage = helium.packages.${pkgs.stdenv.hostPlatform.system}.helium;
                    prependFlags = commonFlags;
                };

                # ungoogled-chromium = {
                #     basePackage = pkgs.ungoogled-chromium;
                #     prependFlags = commonFlags ++ [
                #         "--enable-features=${
                #             lib.concatStringsSep "," [
                #                 "ClearDataOnExit"
                #             ]
                #         }"
                #     ];
                # };

                # microsoft-edge = {
                #     basePackage = pkgs.microsoft-edge;
                #     prependFlags = commonFlags;
                # };

                # brave = {
                #     basePackage = pkgs.brave;
                #     prependFlags = commonFlags;
                # };
            };
        };
}
