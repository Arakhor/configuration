{
  graphical =
    {
      pkgs,
      lib,
      ...
    }:
    let
      # Browser/App Definitions
      browser = "firefox.desktop";
      pdfreader = "org.pwmt.zathura.desktop";
      torrent = "org.transmissionbt.Transmission.desktop";
      video = "mpv.desktop";
      image = "swayimg.desktop";
      editor = "helix.desktop";

      associations = {
        # --- Browsing ---
        "text/html" = browser;
        "application/xhtml+xml" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/about" = browser;
        "x-scheme-handler/unknown" = browser;

        # --- Media ---
        "audio/*" = video;
        "video/*" = video;
        "image/*" = image;
        "image/svg+xml" = image;

        # --- Documents ---
        "application/pdf" = pdfreader;
        "application/epub+zip" = pdfreader;
        "image/vnd.djvu" = pdfreader;
        "application/postscript" = pdfreader;
        "application/vnd.comicbook+zip" = pdfreader;
        "application/vnd.comicbook+rar" = pdfreader;
        "application/x-cbz" = pdfreader;
        "application/x-cbr" = pdfreader;

        # --- Directories ---
        "inode/directory" = "kitty-open.desktop"; # Provided by custom desktop item or we need to ensure it exists?
        # kitty-open is likely a custom desktop file. We might need to migrate it if it was previously managed.
        # For now, let's assume it exists or fallback to kitty.desktop.

        # --- Playlists ---
        "audio/x-mpegurl" = video;
        "application/vnd.apple.mpegurl" = video;
        "application/x-scpls" = video;

        # --- Misc ---
        "x-scheme-handler/magnet" = torrent;

        # --- Archives ---
        "application/zip" = editor;
        "application/x-tar" = editor;
        "application/gzip" = editor;
        "application/x-bzip2" = editor;
        "application/x-7z-compressed" = editor;
        "application/x-rar" = editor;
        "application/x-xz" = editor;

        # --- Editing (Text/Code) ---
        "text/plain" = editor;
        "text/markdown" = editor;
        "text/x-markdown" = editor;
        "text/x-readme" = editor;
        "text/x-log" = editor;
        "text/x-tex" = editor;
        "text/x-diff" = editor;
        "text/x-patch" = editor;
        "application/json" = editor;
        "application/x-shellscript" = editor;
        "application/toml" = editor;
        "application/yaml" = editor;
        "text/x-yaml" = editor;
        "application/xml" = editor;
        "text/xml" = editor;
        "text/x-ini" = editor;
        "text/x-config" = editor;
        "text/csv" = editor;
        "text/x-csv" = editor;
        "text/x-c" = editor;
        "text/x-c++" = editor;
        "text/x-python" = editor;
        "application/x-python" = editor;
        "text/x-php" = editor;
        "application/x-php" = editor;
        "text/x-rust" = editor;
        "text/rust" = editor;
        "text/x-go" = editor;
        "text/x-java" = editor;
        "text/x-lua" = editor;
        "text/x-nix" = editor;
        "text/x-script.python" = editor;
        "text/x-perl" = editor;
        "text/x-ruby" = editor;
        "text/x-makefile" = editor;
        "text/x-dockerfile" = editor;
        "text/x-cmake" = editor;
        "text/css" = editor;
        "application/javascript" = editor;
        "application/typescript" = editor;
        "text/x-sql" = editor;
        "application/sql" = editor;
      };

      mimeAppsList = lib.generators.toINI { } {
        "Default Applications" = associations;
        "Added Associations" = associations;
      };

      # User Dirs
      userDirs = ''
        XDG_DESKTOP_DIR="$HOME/.local/desktop"
        XDG_DOCUMENTS_DIR="$HOME/documents"
        XDG_DOWNLOAD_DIR="$HOME/downloads"
        XDG_MUSIC_DIR="$HOME/music"
        XDG_PICTURES_DIR="$HOME/pictures"
        XDG_PUBLICSHARE_DIR="$HOME/.local/public"
        XDG_TEMPLATES_DIR="$HOME/.local/templates"
        XDG_VIDEOS_DIR="$HOME/videos"
      '';
    in
    {
      # 1. Config Files
      home.file.xdg_config = {
        "mimeapps.list".text = mimeAppsList;
        "user-dirs.dirs".text = userDirs;
      };

      # 2. Activation: Create Directories
      # Using a oneshot service is cleaner than hooking into system activation directly for user dirs
      home.systemd.services.xdg-user-dirs-create = {
        description = "Create XDG User Directories";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = toString (
            pkgs.writeShellScript "create-xdg-dirs" ''
              mkdir -p $HOME/.local/desktop
              mkdir -p $HOME/development
              mkdir -p $HOME/documents
              mkdir -p $HOME/downloads
              mkdir -p $HOME/music
              mkdir -p $HOME/pictures
              mkdir -p $HOME/.local/public
              mkdir -p $HOME/.local/templates
              mkdir -p $HOME/videos
              mkdir -p $HOME/.local/bin
            ''
          );
        };
      };

      preserveHome.directories = [
        "development"
        "documents"
        "downloads"
        "music"
        "pictures"
        "videos"
      ];

      # 3. Environment Variables (optional, but good for shell)
      # NixOS handles XDG_CONFIG_HOME etc, but XDG_DATA_DIRS need to include .local/share/applications?
      # Usually standard.
    };
}
