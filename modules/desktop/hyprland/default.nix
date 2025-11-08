{
  lib,
  config,
  pkgs,
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
  ];

  options.jvf.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland desktop";
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
      Kvantum.enable = true;
      Thunar.enable = true;
      xfce4.enable = true;
    };

    environment.systemPackages = [
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
