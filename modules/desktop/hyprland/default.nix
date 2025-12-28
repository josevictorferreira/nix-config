{ lib
, config
, pkgs
, username
, ...
}:

let
  cfg = config.jvf.desktop.hyprland;
  python-packages = pkgs.python3.withPackages (
    ps: with ps; [
      requests
      pyquery
    ]
  );
in
{
  imports = [
    ./hypr
    ./ags
    ./cava
    ./qt5ct
    ./qt6ct
    ./rofi
    ./swaync
    ./wallust
    ./waybar
    ./wlogout
    ./swappy
    ./kvantum
    ./thunar
    ./xfce4
    ./gtk3
    ./fastfetch
  ];

  options.jvf.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland desktop";

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username to use for Hyprland";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.desktop.hyprland = {
      hypr.enable = true;
      ags.enable = true;
      cava.enable = true;
      qt5ct.enable = true;
      qt6ct.enable = true;
      rofi.enable = true;
      swaync.enable = true;
      wallust.enable = true;
      waybar.enable = true;
      wlogout.enable = true;
      swappy.enable = true;
      kvantum.enable = true;
      thunar.enable = true;
      xfce4.enable = true;
      gtk3 = {
        enable = true;
        folderIcons = {
          "/home/${cfg.username}/Workspace" = "folder-development";
          "/home/${cfg.username}/Homelab" = "folder-cloud";
          "/home/${cfg.username}/.config/nix" = "folder-script";
          "/home/${cfg.username}/.config/nvim" = "folder-script";
          "/home/${cfg.username}/Workspace/homelab" = "folder-cloud";
          "/home/${cfg.username}/Workspace/ai-workspace" = "folder-templates";
          "/home/${cfg.username}/Workspace/valoris" = "folder-publicshare";
          "/home/${cfg.username}/Workspace/agrosmart" = "folder-publicshare";
        };
      };
      fastfetch.enable = true;
    };

    services.greetd.enable = lib.mkDefault false;
    services.displayManager = {
      ly.enable = lib.mkDefault false;
      autoLogin = {
        enable = true;
        user = cfg.username;
      };
      defaultSession = "hyprland";
    };

    users.users."${cfg.username}".packages = [
      pkgs.killall
      pkgs.glib
      pkgs.gsettings-qt
      pkgs.libnotify
      pkgs.libappindicator
      pkgs.slurp
      pkgs.wl-clipboard
      pkgs.brightnessctl
      pkgs.cliphist
      pkgs.eog
      pkgs.gnome-system-monitor
      pkgs.file-roller
      pkgs.gtk-engine-murrine
      pkgs.inxi
      pkgs.networkmanagerapplet
      pkgs.nwg-look
      pkgs.nvtopPackages.full
      pkgs.pamixer
      pkgs.pavucontrol
      pkgs.playerctl
      pkgs.polkit_gnome
      pkgs.yad
      pkgs.yt-dlp
      pkgs.noto-fonts
      pkgs.kitty
      pkgs.fira-code
      pkgs.noto-fonts-cjk-sans
      pkgs.jetbrains-mono
      pkgs.font-awesome
      pkgs.terminus_font
      python-packages
    ];
  };
}
