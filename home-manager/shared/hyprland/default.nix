{ pkgs
, inputs
, configRoot
, ...
}:

let
  hyprlandConfig = "${configRoot}/dotfiles/hypr";
  python-packages = pkgs.python3.withPackages (
    ps: with ps; [
      requests
      pyquery # needed for hyprland-dots Weather script
    ]
  );
in
{
  imports = [
    ./waybar.nix
    ./wallust.nix
    ./screenshot.nix
    ./wlogout.nix
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    xwayland.enable = true;
    extraConfig = builtins.readFile "${hyprlandConfig}/hyprland.conf";
  };
  home.file = {
    ".config/hypr" = {
      source = "${hyprlandConfig}";
      recursive = true;
    };
  };
  home.packages =
    with pkgs;
    [
      slurp
      wl-clipboard
      hypridle
      hyprcursor
      pyprland
      brightnessctl # for brightness control
      cliphist
      eog
      gnome-system-monitor
      file-roller
      gtk-engine-murrine # for gtk themes
      inxi
      networkmanagerapplet
      nwg-look # requires unstable channel
      nvtopPackages.full
      pamixer
      pavucontrol
      playerctl
      polkit_gnome
      yad
      yt-dlp
      noto-fonts

      # GUI Apps
      kitty

      # Fonts
      fira-code
      noto-fonts-cjk-sans
      jetbrains-mono
      font-awesome
      terminus_font
    ]
    ++ [
      python-packages
    ];
}
