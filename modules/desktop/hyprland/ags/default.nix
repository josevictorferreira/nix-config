{
  lib,
  pkgs,
  config,
  username,
  ...
}:

let
  cfg = config.jvf.desktop.hyprland.ags;
in
{
  options.jvf.desktop.hyprland.ags = {
    enable = lib.mkEnableOption "AGS - Awesome Hyprland Widgets";

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username to configure AGS for.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.ags = {
      packages = [
        pkgs.ags
      ];
      configs = {
        "ags" = ./.;
      };
    };
  };
}
