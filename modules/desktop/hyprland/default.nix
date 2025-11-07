{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.jvf.desktop.hyprland;
in
{
  imports = [
    ./ags
    ./cava
    ./qt5ct
    ./qt6ct
    ./rofi
    ./swaync
  ];

  options.jvf.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland desktop";
  };

  config = lib.mkIf cfg.enable {
    jvf.desktop.hyprland = {
      ags.enable = true;
      cava.enable = true;
      qt5ct.enable = true;
      qt6ct.enable = true;
      rofi.enable = true;
      swaync.enable = true;
    };

    environment.systemPackages = [ pkgs.hyprlock ];
  };
}
