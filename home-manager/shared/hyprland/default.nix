{ pkgs, inputs, configRoot, ... }:

let
  hyprlandConfig = "${configRoot}/config/hypr";
  python-packages = pkgs.python3.withPackages (
    ps:
      with ps; [
        requests
        pyquery # needed for hyprland-dots Weather script
      ]
  );
in
{
  imports = [
    ./rofi.nix
    ./waybar.nix
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    xwayland.enable = true;
    extraConfig = builtins.readFile "${hyprlandConfig}/hyprland.conf";
  };
  fonts.fontconfig.enable = true;
  home.file = {
    ".config/hypr" = {
      source = "${hyprlandConfig}";
      recursive = true;
    };
  };
  home.packages = with pkgs; [
    swww
    swaynotificationcenter
    slurp
    wlogout
    wl-clipboard
    hypridle
    hyprcursor
    pyprland
    wallust
    (ags.overrideAttrs (oldAttrs: {
      inherit (oldAttrs) pname;
      version = "1.8.2";
    }))
    brightnessctl # for brightness control
    cliphist
    eog
    gnome-system-monitor
    file-roller
    gtk-engine-murrine #for gtk themes
    inxi
    libsForQt5.qtstyleplugin-kvantum #kvantum
    networkmanagerapplet
    nwg-look # requires unstable channel
    nvtopPackages.full
    pamixer
    pavucontrol
    playerctl
    polkit_gnome
    libsForQt5.qt5ct
    qt6ct
    qt6.qtwayland
    qt6Packages.qtstyleplugin-kvantum #kvantum
    swappy
    yad
    yt-dlp
    noto-fonts

    # GUI Apps
    kitty

    # Screenshot tools
    grim
    grimblast
    hyprshot

    # Fonts
    fira-code
    noto-fonts-cjk-sans
    jetbrains-mono
    font-awesome
    terminus_font
  ] ++ [
    python-packages
  ];

  programs = {
    hyprlock.enable = true;
  };
}
