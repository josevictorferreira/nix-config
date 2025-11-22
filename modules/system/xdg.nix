{
  config,
  lib,
  pkgs,
  username,
  system,
  ...
}:

let
  cfg = config.jvf.system.xdg;
  isDarwin = builtins.match ".*-darwin" system != null;
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
  options.jvf.system.xdg = {
    enable = lib.mkEnableOption "XDG desktop integration configuration" // {
      description = ''
        Whether to enable XDG desktop integration configuration.
        Configures:
        - Desktop portals for application integration
        - MIME type application associations
        - GTK desktop integration
      '';
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
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
        "application/x-chrome-extension" = "org.chromium.Chromium.desktop";
        "application/x-xpinstall" = "org.chromium.Chromium.desktop";

        # --- Text Editor (Custom Alacritty+Nvim) ---
        "text/plain" = "nvim-wrapper.desktop";
        "text/markdown" = "nvim-wrapper.desktop";
        "text/x-chdr" = "nvim-wrapper.desktop";
        "text/x-csrc" = "nvim-wrapper.desktop";
        "text/x-makefile" = "nvim-wrapper.desktop";

        # --- Text Editor (Custom Alacritty+Nvim) ---
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

        # --- File Manager (Thunar) ---
        "inode/directory" = "thunar.desktop";

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
  };

  config = lib.mkIf cfg.enable (
    if (!isDarwin) then
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
      }
    else
      { }
  );
}
