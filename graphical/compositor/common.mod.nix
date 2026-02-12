{
    graphical = {
        programs.uwsm.sessionVariables.common = {
            NIXOS_OZONE_WL = 1;
            GDK_BACKEND = "wayland,x11,*";
            QT_QPA_PLATFORM = "wayland;xcb";
            SDL_VIDEODRIVER = "wayland";
            CLUTTER_BACKEND = "wayland";
            QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        };
    };

    zeph = {
        programs.uwsm.sessionVariables.common = {
            LIBVA_DRIVER_NAME = "nvidia";
            __GLX_VENDOR_LIBRARY_NAME = "nvidia";
            GBM_BACKEND = "nvidia-drm";

            # https://github.com/elFarto/nvidia-vaapi-driver
            NVD_BACKEND = "direct";
            MOZ_DISABLE_RDD_SANDBOX = 1;
        };
    };
}
