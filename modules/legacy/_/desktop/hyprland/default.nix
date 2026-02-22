{
  lib,
  config,
  pkgs,
  username,
  ...
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
    # ./ags migrated to modules/aspects/desktop-hyprland-ags.nix
    ./cava
    ./qt5ct
    ./qt6ct

    ./swaync
    ./wallust
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

      swaync.enable = true;
      wallust.enable = true;
      wlogout.enable = true;
      swappy.enable = true;
      kvantum.enable = true;
      thunar.enable = true;
      xfce4.enable = true;
      gtk3 = {
        enable = true;
        bookmarks = [
          {
            path = "/home/${cfg.username}/Documents";
            name = "Documents";
            icon = "folder-documents";
          }
          {
            path = "/home/${cfg.username}/Pictures";
            name = "Pictures";
            icon = "folder-pictures";
          }
          {
            path = "/home/${cfg.username}/Videos";
            name = "Videos";
            icon = "folder-videos";
          }
          {
            path = "/home/${cfg.username}/Downloads";
            name = "Downloads";
            icon = "folder-download";
          }
          {
            path = "/home/${cfg.username}/Homelab";
            name = "Homelab";
            icon = "folder-cloud";
          }
          {
            path = "/home/${cfg.username}/.config/nix";
            name = "NixConfig";
            icon = "folder-orange-script";
          }
          {
            path = "/home/${cfg.username}/.config/nvim";
            name = "NeovimConfig";
            icon = "folder-green-script";
          }
          {
            path = "/home/${cfg.username}/Workspace";
            name = "Workspace";
            icon = "folder-cyan-development";
          }
          {
            path = "/home/${cfg.username}/Workspace/homelab";
            name = "Homelab";
            icon = "folder-blue-cloud";
          }
          {
            path = "/home/${cfg.username}/Workspace/ai-workspace/comfyui/ComfyUI";
            name = "ComfyUI";
            icon = "folder-magenta-templates";
          }
          {
            path = "/home/${cfg.username}/Workspace/valoris";
            name = "Valoris";
            icon = "folder-teal-publicshare";
          }
          {
            path = "/home/${cfg.username}/Workspace/agrosmart/booster";
            name = "Booster";
            icon = "folder-green-publicshare";
          }
          {
            path = "/home/${cfg.username}/Workspace/agrosmart/agrosmart-api";
            name = "BoosterPro";
            icon = "folder-green-publicshare";
          }
          {
            path = "/home/${cfg.username}/Workspace/agrosmart/nexus/nexus-backend";
            name = "Nexus";
            icon = "folder-violet-publicshare";
          }
        ];
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
