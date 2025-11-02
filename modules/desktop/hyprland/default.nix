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
  ];

  options.jvf.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland desktop";
  };

  config = lib.mkIf cfg.enable {
    jvf.desktop.hyprland = {
      ags.enable = true;
      cava.enable = true;
    };

    environment.systemPackages = [ pkgs.hyprlock ];
  };
}
