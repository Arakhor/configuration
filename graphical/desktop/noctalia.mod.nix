{ noctalia, noctalia-plugins, ... }:
{
    graphical =
        {
            config,
            lib,
            pkgs,
            ...
        }:
        let
            inherit (config) style;

            jsonFormat = pkgs.formats.json { };
        in
        {
            nixpkgs.overlays = [ noctalia.overlays.default ];

            preserveHome.directories = [
                ".cache/noctalia"
                ".config/noctalia"
            ];

            style.dynamic.templates.noctalia-shell = {
                target = ".config/noctalia/colors.json";
                source =
                    with config.lib.style.genMatugenKeys { };
                    jsonFormat.generate "noctalia-colors" {
                        mError = error;
                        mHover = tertiary;
                        mOnError = on_error;
                        mOnHover = on_tertiary;
                        mOnPrimary = on_primary;
                        mOnSecondary = on_secondary;
                        mOnSurface = on_surface;
                        mOnSurfaceVariant = on_surface_variant;
                        mOnTertiary = on_tertiary;
                        mOutline = outline_variant;
                        mPrimary = primary;
                        mSecondary = secondary;
                        mShadow = shadow;
                        mSurface = surface;
                        mSurfaceVariant = surface_container;
                        mTertiary = tertiary;
                    };
            };

            maid-users = {
                packages = [ pkgs.noctalia-shell ];

                systemd.services.noctalia-shell = {
                    description = "Noctalia Shell - Wayland desktop shell";
                    documentation = [ "https://docs.noctalia.dev/docs" ];
                    partOf = [ "graphical-session.target" ];
                    after = [ "graphical-session.target" ];

                    unitConfig.X-Restart-Triggers = [
                        config.users.users.arakhor.maid.file.xdg_config."noctalia/settings.json".source
                        config.users.users.arakhor.maid.file.xdg_config."noctalia/plugins.json".source
                    ];

                    environment.PATH = lib.mkForce null;

                    serviceConfig = {
                        ExecStart = lib.getExe pkgs.noctalia-shell;
                        Restart = "on-failure";
                        Environment = [
                            "NOCTALIA_SETTINGS_FALLBACK=%h/.config/noctalia/gui-settings.json"
                        ];
                        Slice = config.lib.session.appSlice;
                    };

                    wantedBy = [ "graphical-session.target" ];
                };

                file.xdg_config = {
                    "noctalia/plugins".source = noctalia-plugins;
                    "noctalia/plugins.json".source = jsonFormat.generate "plugins" {
                        states.catwalk.enabled = true;
                    };
                    "noctalia/settings.json".source = jsonFormat.generate "settings" {
                        templates.enableUserTemplates = false;
                        colorSchemes.useWallpaperColors = false;

                        general =
                            let
                                ratio = style.cornerRadius / 20.0;
                            in
                            {
                                allowPanelsOnScreenWithoutBar = true;
                                animationDisabled = false;
                                animationSpeed = 1;
                                avatarImage = "/home/arakhor/.face";
                                compactLockScreen = false;
                                dimmerOpacity = 0.2;
                                enableShadows = true;

                                boxRadiusRatio = ratio;
                                iRadiusRatio = ratio;
                                radiusRatio = ratio;
                                screenRadiusRatio = ratio;

                                language = "";
                                lockOnSuspend = true;
                                scaleRatio = 1;

                                shadowDirection = "bottom_right";
                                shadowOffsetX = 2;
                                shadowOffsetY = 3;
                                showHibernateOnLockScreen = false;
                                showScreenCorners = true;
                                forceBlackScreenCorners = true;
                                showSessionButtonsOnLockScreen = true;
                            };

                        audio = {
                            cavaFrameRate = 60;
                            externalMixer = "pwvucontrol || pavucontrol";
                            mprisBlacklist = [ ];
                            preferredPlayer = "";
                            visualizerType = "linear";
                            volumeOverdrive = false;
                            volumeStep = 5;
                        };

                        bar = {
                            backgroundOpacity = config.style.opacity;
                            capsuleOpacity = config.style.opacity;
                            density = "comfortable";
                            exclusive = true;
                            floating = false;
                            marginHorizontal = 0.25;
                            marginVertical = 0.25;
                            outerCorners = false;
                            position = "bottom";
                            showCapsule = false;
                            showOutline = false;
                            useSeparateOpacity = false;
                            widgets = {
                                left = [
                                    {
                                        id = "SystemMonitor";
                                        compactMode = true;
                                        diskPath = "/state";
                                        showCpuTemp = true;
                                        showCpuUsage = true;
                                        showDiskUsage = false;
                                        showGpuTemp = false;
                                        showLoadAverage = false;
                                        showMemoryAsPercent = false;
                                        showMemoryUsage = true;
                                        showNetworkStats = false;
                                        useMonospaceFont = true;
                                        usePrimaryColor = false;
                                    }
                                    {
                                        id = "Taskbar";
                                        colorizeIcons = false;
                                        hideMode = "hidden";
                                        iconScale = 0.8;
                                        maxTaskbarWidth = 75;
                                        onlyActiveWorkspaces = true;
                                        onlySameOutput = true;
                                        showPinnedApps = true;
                                        showTitle = true;
                                        smartWidth = true;
                                        titleWidth = 120;
                                    }
                                    {
                                        id = "plugin:catwalk";
                                        defaultSettings = {
                                            hideBackground = false;
                                            minimumThreshold = 10;
                                        };
                                    }
                                ];
                                center = [ ];
                                right = [
                                    {
                                        id = "Tray";
                                        blacklist = [ ];
                                        colorizeIcons = false;
                                        drawerEnabled = true;
                                        hidePassive = false;
                                        pinned = [ ];
                                    }
                                    {
                                        id = "Microphone";
                                        displayMode = "onhover";
                                        middleClickCommand = "pwvucontrol || pavucontrol";
                                    }
                                    {
                                        id = "Volume";
                                        displayMode = "onhover";
                                        middleClickCommand = "pwvucontrol || pavucontrol";
                                    }
                                    {
                                        id = "Battery";
                                        deviceNativePath = "";
                                        displayMode = "onhover";
                                        hideIfNotDetected = true;
                                        showNoctaliaPerformance = true;
                                        showPowerProfiles = true;
                                        warningThreshold = 30;
                                    }
                                    {
                                        id = "Network";
                                        displayMode = "onhover";
                                    }
                                    {
                                        id = "Bluetooth";
                                        displayMode = "onhover";
                                    }
                                    { id = "PowerProfile"; }
                                    {
                                        id = "NotificationHistory";
                                        hideWhenZero = false;
                                        hideWhenZeroUnread = false;
                                        showUnreadBadge = true;
                                    }
                                    {
                                        id = "CustomButton";
                                        colorizeSystemIcon = "secondary";
                                        enableColorization = true;
                                        hideMode = "alwaysExpanded";
                                        icon = "wallpaper";
                                        ipcIdentifier = "";
                                        leftClickExec = "noctalia-shell ipc call wallpaper toggle";
                                        leftClickUpdateText = true;
                                        maxTextLength = {
                                            horizontal = 10;
                                            vertical = 10;
                                        };
                                        middleClickExec = "";
                                        middleClickUpdateText = false;
                                        parseJson = false;
                                        rightClickExec = "";
                                        rightClickUpdateText = false;
                                        showIcon = true;
                                        textCollapse = "";
                                        textCommand = "";
                                        textIntervalMs = 3000;
                                        textStream = false;
                                        wheelDownExec = "";
                                        wheelDownUpdateText = false;
                                        wheelExec = "";
                                        wheelMode = "unified";
                                        wheelUpExec = "";
                                        wheelUpUpdateText = false;
                                        wheelUpdateText = false;
                                    }
                                    {
                                        colorizeSystemIcon = "secondary";
                                        enableColorization = true;
                                        hideMode = "alwaysExpanded";
                                        icon = "settings";
                                        id = "CustomButton";
                                        ipcIdentifier = "";
                                        leftClickExec = "noctalia-shell ipc call settings toggle";
                                        leftClickUpdateText = true;
                                        maxTextLength = {
                                            horizontal = 10;
                                            vertical = 10;
                                        };
                                        middleClickExec = "";
                                        middleClickUpdateText = false;
                                        parseJson = false;
                                        rightClickExec = "";
                                        rightClickUpdateText = false;
                                        showIcon = true;
                                        textCollapse = "";
                                        textCommand = "";
                                        textIntervalMs = 3000;
                                        textStream = false;
                                        wheelDownExec = "";
                                        wheelDownUpdateText = false;
                                        wheelExec = "";
                                        wheelMode = "unified";
                                        wheelUpExec = "";
                                        wheelUpUpdateText = false;
                                        wheelUpdateText = false;
                                    }
                                    {
                                        colorName = "error";
                                        id = "SessionMenu";
                                    }
                                    {
                                        id = "Clock";
                                        customFont = "";
                                        formatHorizontal = "HH:mm ddd, MMM dd";
                                        formatVertical = "HH mm - dd MM";
                                        tooltipFormat = "HH:mm ddd, MMM dd";
                                        useCustomFont = false;
                                        usePrimaryColor = true;
                                    }
                                ];
                            };
                        };

                        brightness = {
                            brightnessStep = 5;
                            enableDdcSupport = false;
                            enforceMinimum = false;
                        };

                        calendar = {
                            cards = [
                                {
                                    id = "calendar-header-card";
                                    enabled = true;
                                }
                                {
                                    id = "calendar-month-card";
                                    enabled = true;
                                }
                                {
                                    id = "timer-card";
                                    enabled = true;
                                }
                                {
                                    id = "weather-card";
                                    enabled = true;
                                }
                            ];
                        };

                        controlCenter = {
                            diskPath = "/state";
                            cards = [
                                {
                                    enabled = true;
                                    id = "profile-card";
                                }
                                {
                                    enabled = true;
                                    id = "shortcuts-card";
                                }
                                {
                                    enabled = false;
                                    id = "audio-card";
                                }
                                {
                                    enabled = false;
                                    id = "brightness-card";
                                }
                                {
                                    enabled = true;
                                    id = "weather-card";
                                }
                                {
                                    enabled = false;
                                    id = "media-sysmon-card";
                                }
                            ];
                            position = "close_to_bar_button";
                            shortcuts = {
                                left = [
                                    { id = "Network"; }
                                    { id = "Bluetooth"; }
                                    { id = "ScreenRecorder"; }
                                    { id = "WallpaperSelector"; }
                                ];
                                right = [
                                    { id = "Notifications"; }
                                    { id = "PowerProfile"; }
                                    { id = "KeepAwake"; }
                                    { id = "NightLight"; }
                                ];
                            };
                        };

                        dock.enabled = false;

                        location = {
                            name = "Warsaw";
                            analogClockInCalendar = false;
                            firstDayOfWeek = -1;
                            showCalendarEvents = true;
                            showCalendarWeather = true;
                            showWeekNumberInCalendar = false;
                            use12hourFormat = false;
                            useFahrenheit = false;
                            weatherEnabled = true;
                            weatherShowEffects = true;
                        };

                        network = {
                            bluetoothDetailsViewMode = "grid";
                            bluetoothHideUnnamedDevices = false;
                            bluetoothRssiPollIntervalMs = 10000;
                            bluetoothRssiPollingEnabled = false;
                            wifiDetailsViewMode = "grid";
                            wifiEnabled = true;
                        };

                        nightLight = {
                            autoSchedule = true;
                            dayTemp = "6500";
                            enabled = false;
                            forced = false;
                            manualSunrise = "06:30";
                            manualSunset = "18:30";
                            nightTemp = "4000";
                        };

                        notifications = {
                            backgroundOpacity = style.opacity;
                            criticalUrgencyDuration = 15;
                            enableKeyboardLayoutToast = true;
                            enabled = true;
                            location = "top_right";
                            lowUrgencyDuration = 3;
                            monitors = [ ];
                            normalUrgencyDuration = 8;
                            overlayLayer = true;
                            respectExpireTimeout = false;
                            saveToHistory = {
                                critical = true;
                                low = true;
                                normal = true;
                            };
                            sounds = {
                                enabled = true;
                                excludedApps = "discord,firefox,chrome,chromium,edge";
                                lowSoundFile = "";
                                normalSoundFile = "";
                                criticalSoundFile = "";
                                separateSounds = false;
                                volume = 0.5;
                            };
                        };

                        osd = {
                            enabled = true;
                            autoHideMs = 2000;
                            backgroundOpacity = style.opacity;
                            enabledTypes = [
                                0
                                1
                                2
                                4
                            ];
                            location = "top_right";
                            monitors = [ ];
                            overlayLayer = true;
                        };

                        screenRecorder = {
                            audioCodec = "opus";
                            audioSource = "default_output";
                            colorRange = "limited";
                            copyToClipboard = false;
                            directory = "/home/arakhor/videos";
                            frameRate = 60;
                            quality = "very_high";
                            showCursor = true;
                            videoCodec = "h264";
                            videoSource = "portal";
                        };

                        sessionMenu = {
                            countdownDuration = 10000;
                            enableCountdown = true;
                            largeButtonsStyle = false;
                            position = "center";
                            powerOptions = [
                                {
                                    action = "lock";
                                    command = "";
                                    countdownEnabled = true;
                                    enabled = true;
                                }
                                {
                                    action = "suspend";
                                    command = "";
                                    countdownEnabled = true;
                                    enabled = true;
                                }
                                {
                                    action = "hibernate";
                                    command = "";
                                    countdownEnabled = true;
                                    enabled = true;
                                }
                                {
                                    action = "reboot";
                                    command = "";
                                    countdownEnabled = true;
                                    enabled = true;
                                }
                                {
                                    action = "logout";
                                    command = "";
                                    countdownEnabled = true;
                                    enabled = true;
                                }
                                {
                                    action = "shutdown";
                                    command = "";
                                    countdownEnabled = true;
                                    enabled = true;
                                }
                            ];
                            showHeader = true;
                            showNumberLabels = true;
                        };

                        systemMonitor = {
                            enableDgpuMonitoring = false;
                            cpuCriticalThreshold = 90;
                            cpuPollingInterval = 3000;
                            cpuWarningThreshold = 80;
                            criticalColor = "";
                            diskCriticalThreshold = 90;
                            diskPath = "/";
                            diskPollingInterval = 3000;
                            diskWarningThreshold = 80;
                            gpuCriticalThreshold = 90;
                            gpuPollingInterval = 3000;
                            gpuWarningThreshold = 80;
                            memCriticalThreshold = 90;
                            memPollingInterval = 3000;
                            memWarningThreshold = 80;
                            networkPollingInterval = 3000;
                            tempCriticalThreshold = 90;
                            tempPollingInterval = 3000;
                            tempWarningThreshold = 80;
                            useCustomColors = false;
                            warningColor = "";
                        };

                        ui = {
                            fontDefault = style.fonts.sansSerif.name;
                            fontFixed = style.fonts.monospace.name;
                            panelBackgroundOpacity = style.opacity;
                            bluetoothDetailsViewMode = "grid";
                            bluetoothHideUnnamedDevices = false;
                            boxBorderEnabled = false;
                            fontDefaultScale = 1;
                            fontFixedScale = 1;
                            networkPanelView = "wifi";
                            panelsAttachedToBar = true;
                            settingsPanelMode = "attached";
                            tooltipsEnabled = true;
                            wifiDetailsViewMode = "grid";
                        };

                        hooks = {
                            enabled = false;
                            darkModeChange = "";
                            performanceModeDisabled = "";
                            performanceModeEnabled = "";
                            screenLock = "";
                            screenUnlock = "";
                            wallpaperChange = "";
                        };

                        wallpaper = {
                            randomIntervalSec = 60 * 60; # change every hour
                            directory = style.dynamic.wallpapersDir;
                            enableMultiMonitorDirectories = false;
                            enabled = true;
                            fillColor = "#000000";
                            fillMode = "crop";
                            hideWallpaperFilenames = false;
                            monitorDirectories = [ ];
                            overviewEnabled = false;
                            panelPosition = "follow_bar";
                            randomEnabled = true;
                            recursiveSearch = false;
                            setWallpaperOnAllMonitors = true;
                            transitionDuration = 1500;
                            transitionEdgeSmoothness = 0.05;
                            transitionType = "random";

                            useWallhaven = false;
                            wallhavenApiKey = "";
                            wallhavenCategories = "111";
                            wallhavenOrder = "desc";
                            wallhavenPurity = "100";
                            wallhavenQuery = "";
                            wallhavenRatios = "";
                            wallhavenResolutionHeight = "";
                            wallhavenResolutionMode = "atleast";
                            wallhavenResolutionWidth = "";
                            wallhavenSorting = "relevance";
                            wallpaperChangeMode = "random";
                        };
                    };

                };
            };

            programs.niri.settings.layer-rules = [
                {
                    matches = [ { namespace = "^noctalia-wallpaper*"; } ];
                    place-within-backdrop = true;
                }
            ];

        };

    zeph.maid-users =
        { pkgs, lib, ... }:
        let
            pastel = lib.getExe pkgs.pastel;
            asusctl = lib.getExe' pkgs.asusctl "asusctl";
        in
        {
            systemd = {
                services.noctalia-shell-asuscolor = {
                    serviceConfig = {
                        Type = "oneshot";
                        ExecStart = pkgs.writers.writeNu "noctalia-shell-asuscolor-script" ''
                            let color = open /home/arakhor/.config/noctalia/colors.json
                            | get mPrimary
                            | ${pastel} set hsl-lightness 0.55
                            | ${pastel} set hsl-saturation 0.8
                            | ${pastel} format hex
                            | str substring 1.. 
                            ${asusctl} aura static -c $color
                        '';
                    };
                    partOf = [ "noctalia-shell.service" ];
                    after = [ "noctalia-shell.service" ];
                    wantedBy = [ "noctalia-shell.service" ];
                };

                paths.noctalia-shell-asuscolor = {
                    pathConfig.PathChanged = "/home/arakhor/.config/noctalia/colors.json";
                    partOf = [ "noctalia-shell.service" ];
                    wantedBy = [ "noctalia-shell.service" ];
                };
            };
        };
}
