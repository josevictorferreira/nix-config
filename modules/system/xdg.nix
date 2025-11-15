{ config
, lib
, pkgs
, username
, ...
}:

let
  cfg = config.jvf.system.xdg;
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
        "application/pdf" = "org.pwmt.zathura.desktop";
        "application/x-pdf" = "org.pwmt.zathura.desktop";
        "application/epub+zip" = "org.koreader.koreader.desktop";
        "application/x-mobipocket-ebook" = "org.koreader.koreader.desktop";
        "application/x-chrome-extension" = "org.chromium.Chromium.desktop";
        "application/x-xpinstall" = "org.chromium.Chromium.desktop";
        "inode/directory" = "thunar.desktop";
        "text/plain" = "org.xfce.mousepad.desktop";
        "text/csv" = "calc.desktop";
        "application/octet-stream" = "vlc.desktop";
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

  config = lib.mkIf cfg.enable {
    users.users."${cfg.username}".packages = [
      pkgs.xdg-user-dirs
      pkgs.xdg-utils
    ];

    xdg = {
      mime = lib.mkIf cfg.enableMimeDefaults {
        enable = true;
        defaultApplications = cfg.mimeDefaults;
      };

      portal = lib.mkIf cfg.enablePortals {
        enable = true;
        wlr.enable = cfg.portalWlr;
        extraPortals = lib.mkIf cfg.portalGnome [
          pkgs.xdg-desktop-portal-gtk
        ];
        configPackages = lib.mkIf cfg.portalGnome [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal
        ];
      };
    };
  };
}
