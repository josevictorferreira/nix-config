{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.jvf.desktop.hyprland;
in
{
  imports = [
    ./ags
  ];

  options.jvf.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland desktop";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ags;
      description = "Enable hyprland desktop.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.desktop.hyprland.ags.enable = true;
  };
}
