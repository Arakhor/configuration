{
    graphical =
        {
            pkgs,
            lib,
            config,
            ...
        }:
        let
            inherit (lib) genAttrs mergeAttrsList;

            # Browser/App Definitions
            browser = "glide-browser-bin.desktop";
            pdfreader = "org.pwmt.zathura.desktop";
            torrent = "org.transmissionbt.Transmission.desktop";
            video = "mpv.desktop";
            audio = video;
            image = "swayimg.desktop";
            editor = "helix.desktop";
            fileManager = "org.gnome.Nautilus.desktop";
            terminal = "com.mitchellh.ghostty.desktop";

            associations = mergeAttrsList [
                (genAttrs [
                    "text/html"
                    "application/xhtml+xml"
                    "x-scheme-handler/http"
                    "x-scheme-handler/https"
                    "x-scheme-handler/about"
                    "x-scheme-handler/unknown"
                ] (_: browser))

                (genAttrs [ "audio/*" ] (_: audio))
                (genAttrs [ "video/*" ] (_: video))
                (genAttrs [ "image/*" ] (_: image))
                (genAttrs [ "x-scheme-handler/magnet" ] (_: torrent))

                (genAttrs [
                    "application/pdf"
                    "application/epub+zip"
                    "image/vnd.djvu"
                    "application/postscript"
                    "application/vnd.comicbook+zip"
                    "application/vnd.comicbook+rar"
                    "application/x-cbz"
                    "application/x-cbr"
                ] (_: pdfreader))

                (genAttrs [
                    "inode/directory"
                    "application/zip"
                    "application/x-tar"
                    "application/gzip"
                    "application/x-bzip2"
                    "application/x-7z-compressed"
                    "application/x-rar"
                    "application/x-xz"
                ] (_: fileManager))

                (genAttrs [
                    "text/plain"
                    "text/markdown"
                    "text/x-markdown"
                    "text/x-readme"
                    "text/x-log"
                    "text/x-tex"
                    "text/x-diff"
                    "text/x-patch"
                    "application/json"
                    "application/x-shellscript"
                    "application/toml"
                    "application/yaml"
                    "text/x-yaml"
                    "application/xml"
                    "text/xml"
                    "text/x-ini"
                    "text/x-config"
                    "text/csv"
                    "text/x-csv"
                    "text/x-c"
                    "text/x-c++"
                    "text/x-python"
                    "application/x-python"
                    "text/x-php"
                    "application/x-php"
                    "text/x-rust"
                    "text/rust"
                    "text/x-go"
                    "text/x-java"
                    "text/x-lua"
                    "text/x-nix"
                    "text/x-script.python"
                    "text/x-perl"
                    "text/x-ruby"
                    "text/x-makefile"
                    "text/x-dockerfile"
                    "text/x-cmake"
                    "text/css"
                    "application/javascript"
                    "application/typescript"
                    "text/x-sql"
                    "application/sql"
                ] (_: editor))

                {
                    "x-scheme-handler/terminal" = "xdg-terminal-exec";
                }
            ];

            # User Dirs
            userDirs = {
                XDG_DOCUMENTS_DIR = "documents";
                XDG_DOWNLOAD_DIR = "downloads";
                XDG_MUSIC_DIR = "music";
                XDG_PICTURES_DIR = "pictures";
                XDG_SCREENSHOTS_DIR = "pictures/screenshots";
                XDG_VIDEOS_DIR = "videos";
                XDG_DESKTOP_DIR = ".local/desktop";
                XDG_PUBLICSHARE_DIR = ".local/public";
                XDG_TEMPLATES_DIR = ".local/templates";
            };

            mimeAppsList = lib.generators.toINI { } {
                "Default Applications" = associations;
                "Added Associations" = associations;
            };

            userDirsList =
                let
                    # For some reason, these need to be wrapped with quotes to be valid.
                    wrapped = lib.mapAttrs (_: value: ''"$HOME/${value}"'') userDirs;
                in
                lib.generators.toKeyValue { } wrapped;
        in
        {
            environment.systemPackages = with pkgs; [
                xdg-utils
                xdg-terminal-exec
            ];

            programs.nushell.initConfig = # nu
                ''
                    open ${config.users.users.arakhor.maid.file.xdg_config."user-dirs.dirs".source}
                    | lines
                    | parse "{variable}=\"{value}\""
                    | update value {|row| $row.value | str replace '$HOME' ($nu.home-dir)}
                    | transpose -dr
                    | load-env
                '';

            maid-users = {
                file.xdg_config = {
                    "user-dirs.dirs".text = userDirsList;
                    "mimeapps.list".text = mimeAppsList;
                    "xdg-terminals.list".text = terminal;
                };

                # systemd.tmpfiles.dynamicRules = (
                #     map (d: "d {{home}}/${d} 0755 {{user}} {{group}} - -") [
                #         "documents"
                #         "downloads"
                #         "music"
                #         "pictures"
                #         "pictures/screenshots"
                #         "videos"
                #         ".local/desktop"
                #         ".local/public"
                #         ".local/templates"
                #     ]
                # );
            };

            preserveHome.directories = [
                "documents"
                "downloads"
                "music"
                "pictures"
                "pictures/screenshots"
                "videos"
                ".local/desktop"
                ".local/public"
                ".local/templates"
            ];
        };
}
