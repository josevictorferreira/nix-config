# Aspect: system-xdg
# Defines jvf.system.xdg options and platform-specific XDG config.
# NixOS: portals, MIME associations, user directories, activation scripts.
# Darwin: empty config (no XDG desktop integration).
_:
let
  mkXdgOptions =
    { config, lib, ... }:
    {
      options.jvf.system.xdg = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "The username to use for XDG configurations.";
        };

        enableMimeDefaults = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable default MIME type application associations.";
        };

        mimeDefaults = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            # --- Default Browser (Brave) ---
            "text/html" = "brave-browser.desktop";
            "x-scheme-handler/http" = "brave-browser.desktop";
            "x-scheme-handler/https" = "brave-browser.desktop";
            "x-scheme-handler/about" = "brave-browser.desktop";
            "x-scheme-handler/unknown" = "brave-browser.desktop";
            "application/x-chrome-extension" = "brave-browser.desktop";
            "application/x-xpinstall" = "brave-browser.desktop";

            # --- Text Editor (Custom Alacritty+Nvim) ---
            "text/plain" = "nvim-wrapper.desktop";
            "text/markdown" = "nvim-wrapper.desktop";
            "text/x-chdr" = "nvim-wrapper.desktop";
            "text/x-csrc" = "nvim-wrapper.desktop";
            "text/x-makefile" = "nvim-wrapper.desktop";

            # --- Code/Config Files ---
            "application/json" = "nvim-wrapper.desktop";
            "application/toml" = "nvim-wrapper.desktop";
            "application/yaml" = "nvim-wrapper.desktop";
            "application/x-yaml" = "nvim-wrapper.desktop";

            # --- Documents and Spreadsheets ---
            "application/pdf" = "org.pwmt.zathura.desktop";
            "application/x-pdf" = "org.pwmt.zathura.desktop";
            "application/epub+zip" = "org.koreader.koreader.desktop";
            "application/x-mobipocket-ebook" = "org.koreader.koreader.desktop";
            "text/csv" = "calc.desktop";
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "calc.desktop"; # .xlsx
            "application/vnd.oasis.opendocument.spreadsheet" = "calc.desktop"; # .ods

            # --- File Manager (Yazi) ---
            "inode/directory" = "yazi-fm.desktop";
            "application/x-directory" = "yazi-fm.desktop";

            # --- Images (Imv) ---
            "image/avif" = "imv.desktop";
            "image/bmp" = "imv.desktop";
            "image/gif" = "imv.desktop";
            "image/heic" = "imv.desktop";
            "image/heif" = "imv.desktop";
            "image/jpeg" = "imv.desktop";
            "image/jxl" = "imv.desktop";
            "image/png" = "imv.desktop";
            "image/svg+xml" = "imv.desktop";
            "image/tiff" = "imv.desktop";
            "image/webp" = "imv.desktop";
            "image/x-icon" = "imv.desktop";
            "image/x-portable-anymap" = "imv.desktop";
            "image/x-portable-bitmap" = "imv.desktop";
            "image/x-portable-graymap" = "imv.desktop";
            "image/x-portable-pixmap" = "imv.desktop";
            "image/x-xbitmap" = "imv.desktop";
            "image/x-xpixmap" = "imv.desktop";

            # --- Video/Audio (VLC) ---
            "application/octet-stream" = "vlc.desktop";
            "audio/flac" = "vlc.desktop";
            "audio/mp4" = "vlc.desktop";
            "audio/mpeg" = "vlc.desktop"; # .mp3
            "audio/ogg" = "vlc.desktop";
            "audio/opus" = "vlc.desktop";
            "audio/x-aac" = "vlc.desktop";
            "audio/x-flac" = "vlc.desktop";
            "audio/x-matroska" = "vlc.desktop";
            "audio/x-mp3" = "vlc.desktop";
            "audio/x-mpegurl" = "vlc.desktop";
            "audio/x-ms-wma" = "vlc.desktop";
            "audio/x-vorbis+ogg" = "vlc.desktop";
            "audio/x-wav" = "vlc.desktop";
            "video/avi" = "vlc.desktop";
            "video/mp2t" = "vlc.desktop";
            "video/mp4" = "vlc.desktop";
            "video/mpeg" = "vlc.desktop";
            "video/ogg" = "vlc.desktop";
            "video/quicktime" = "vlc.desktop";
            "video/webm" = "vlc.desktop";
            "video/x-avi" = "vlc.desktop";
            "video/x-flv" = "vlc.desktop";
            "video/x-matroska" = "vlc.desktop"; # .mkv
            "video/x-ms-asf" = "vlc.desktop";
            "video/x-ms-wmv" = "vlc.desktop";
            "video/x-msvideo" = "vlc.desktop";
            "video/x-theora+ogg" = "vlc.desktop";
            "video/x-matroska-3d" = "vlc.desktop";

            # --- Archives (Yazi) ---
            "application/gzip" = "yazi-fm.desktop";
            "application/vnd.rar" = "yazi-fm.desktop";
            "application/x-7z-compressed" = "yazi-fm.desktop";
            "application/x-ace" = "yazi-fm.desktop";
            "application/x-arj" = "yazi-fm.desktop";
            "application/x-bzip" = "yazi-fm.desktop";
            "application/x-bzip-compressed-tar" = "yazi-fm.desktop";
            "application/x-bzip2" = "yazi-fm.desktop";
            "application/x-cabinet" = "yazi-fm.desktop";
            "application/x-compress" = "yazi-fm.desktop";
            "application/x-compressed-tar" = "yazi-fm.desktop";
            "application/x-cpio" = "yazi-fm.desktop";
            "application/x-java-archive" = "yazi-fm.desktop";
            "application/x-lha" = "yazi-fm.desktop";
            "application/x-lrzip" = "yazi-fm.desktop";
            "application/x-lzip" = "yazi-fm.desktop";
            "application/x-lzma" = "yazi-fm.desktop";
            "application/x-lzop" = "yazi-fm.desktop";
            "application/x-rar-compressed" = "yazi-fm.desktop";
            "application/x-rpm" = "yazi-fm.desktop";
            "application/x-source-rpm" = "yazi-fm.desktop";
            "application/x-stuffit" = "yazi-fm.desktop";
            "application/x-tar" = "yazi-fm.desktop";
            "application/x-xz" = "yazi-fm.desktop";
            "application/x-xz-compressed-tar" = "yazi-fm.desktop";
            "application/x-zoo" = "yazi-fm.desktop";
            "application/x-zstd" = "yazi-fm.desktop";
            "application/zip" = "yazi-fm.desktop";
            "application/x-7z-compressed-tar" = "yazi-fm.desktop";
            "application/x-apple-diskimage" = "yazi-fm.desktop";
            "application/x-archive" = "yazi-fm.desktop";
            "application/x-unix-archive" = "yazi-fm.desktop";
            "application/x-debian-binary-package" = "yazi-fm.desktop";
            "application/x-ms-dos-executable" = "yazi-fm.desktop";
            "application/x-msi" = "yazi-fm.desktop";
            "application/x-iso9660-image" = "yazi-fm.desktop";
            "application/x-raw-disk-image" = "yazi-fm.desktop";
            "application/x-raw-disk-image-xz-compressed" = "yazi-fm.desktop";
            "application/x-par2" = "yazi-fm.desktop";
            "application/x-servicepack" = "yazi-fm.desktop";
            "application/x-msdownload" = "yazi-fm.desktop";
            "application/x-dms" = "yazi-fm.desktop";
            "application/x-bsdiff" = "yazi-fm.desktop";
            "application/x-ext2-image" = "yazi-fm.desktop";
            "application/x-ext3-image" = "yazi-fm.desktop";
            "application/x-ext4-image" = "yazi-fm.desktop";
            "application/x-gpt" = "yazi-fm.desktop";
            "application/x-vhd" = "yazi-fm.desktop";
            "application/x-vhdx" = "yazi-fm.desktop";
            "application/x-vmdk" = "yazi-fm.desktop";
            "application/x-qed" = "yazi-fm.desktop";
            "application/x-qcow" = "yazi-fm.desktop";
            "application/x-qcow2" = "yazi-fm.desktop";
            "application/x-virtualbox-vdi" = "yazi-fm.desktop";
            "application/x-virtualbox-vhd" = "yazi-fm.desktop";
            "application/x-virtualbox-vhdx" = "yazi-fm.desktop";
          };
          description = "Mapping of MIME types to default applications (.desktop files).";
        };

        enablePortals = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable XDG desktop portals.";
        };

        portalGnome = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install GTK portal for desktop integration.";
        };

        portalWlr = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Install Wayland WLR portal (for Wayland-native apps).";
        };

        userDirs = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = lib.literalExpression ''
            {
              DOWNLOAD = "$HOME/Downloads";
              DOCUMENTS = "$HOME/Documents";
              PICTURES = "$HOME/Pictures";
            }
          '';
          description = ''
            XDG user directories mapping. Keys are directory names (DOWNLOAD, DOCUMENTS, etc.),
            values are paths. Use $HOME for the home directory.
          '';
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.system.xdg;
      nvimWrapper = pkgs.makeDesktopItem {
        name = "nvim-wrapper";
        desktopName = "Neovim Wrapper";
        exec = "${lib.getExe pkgs.alacritty} -e ${lib.getExe pkgs.neovim} %F";
        icon = "nvim";
        terminal = false;
        type = "Application";
        categories = [
          "Utility"
          "TextEditor"
        ];
        mimeTypes = [
          "text/plain"
          "text/markdown"
          "text/x-makefile"
        ];
      };
    in
    {
      imports = [ mkXdgOptions ];

      config =
        if (!isDarwin) then
          let
            home = "/home/${cfg.username}";
            # Generate user-dirs.dirs content
            userDirsContent = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (name: path: ''XDG_${name}_DIR="${path}"'') cfg.userDirs
            );
          in
          {
            users.users."${cfg.username}".packages = [
              pkgs.xdg-user-dirs
              pkgs.xdg-utils

              nvimWrapper
            ];

            xdg = {
              mime = lib.mkIf cfg.enableMimeDefaults {
                enable = true;
                defaultApplications = cfg.mimeDefaults;
              };

              portal = lib.mkIf cfg.enablePortals {
                enable = true;
                extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
                config = {
                  common = {
                    default = [ "gtk" ];
                  };
                  hyprland = {
                    default = [
                      "gtk"
                      "hyprland"
                    ];
                  };
                };
              };
            };

            systemd.user.tmpfiles.rules = [
              "L+ %h/.config/mimeapps.list - - - - /etc/xdg/mimeapps.list"
            ];

            # Create user-dirs.dirs and user-dirs.locale if userDirs is configured
            system.activationScripts."xdg-user-dirs-${cfg.username}" = lib.mkIf (cfg.userDirs != { }) {
              text =
                let
                  userDirsFile = pkgs.writeText "user-dirs.dirs" ''
                    # This file is written by xdg-user-dirs-update
                    # If you want to change or add directories, just edit the line you're
                    # interested in. All local changes will be retained on the next run.
                    # Format is XDG_xxx_DIR="$HOME/yyy", where yyy is a shell-escaped
                    # homedir-relative path, or XDG_xxx_DIR="/yyy", where /yyy is an
                    # absolute path. No other format is supported.
                    ${userDirsContent}
                  '';
                in
                ''
                  echo "Setting up XDG user directories for ${cfg.username}..."
                  mkdir -p ${home}/.config
                  cp ${userDirsFile} ${home}/.config/user-dirs.dirs
                  echo "en_US" > ${home}/.config/user-dirs.locale
                  chown ${cfg.username}:users ${home}/.config/user-dirs.dirs ${home}/.config/user-dirs.locale
                  chmod 644 ${home}/.config/user-dirs.dirs ${home}/.config/user-dirs.locale
                '';
            };
          }
        else
          { };
    };
in
{
  flake.modules.nixos.system-xdg = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-xdg = mkConfig { isDarwin = true; };
}
