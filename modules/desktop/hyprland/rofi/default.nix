{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.jvf.desktop.hyprland.rofi;
in
{
  options.jvf.desktop.hyprland.rofi = {
    enable = mkEnableOption "rofi";
  };

  config = mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.rofi = {
      packages = [
        pkgs.rofi
      ];
      configs = {
        "rofi" = ./.;
      };
    };
  };
}
