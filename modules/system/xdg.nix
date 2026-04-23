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
            "image/jpeg" = "imv.desktop";
            "image/png" = "imv.desktop";
            "image/gif" = "imv.desktop";
            "image/webp" = "imv.desktop";
            "image/svg+xml" = "imv.desktop";

            # --- Video/Audio (VLC) ---
            "application/octet-stream" = "vlc.desktop";
            "video/mp4" = "vlc.desktop";
            "video/x-matroska" = "vlc.desktop"; # .mkv
            "video/webm" = "vlc.desktop";
            "audio/mpeg" = "vlc.desktop"; # .mp3
            "audio/x-wav" = "vlc.desktop";
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
    {
      config,
      lib,
      pkgs,
      ...
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
