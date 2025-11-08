{
  lib,
  config,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.jvf.desktop.hyprland.rofi;
in
{
  options.jvf.desktop.hyprland.rofi = {
    enable = mkEnableOption "Rofi application launcher and dmenu replacement";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure nvim wrapper";
    };
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
