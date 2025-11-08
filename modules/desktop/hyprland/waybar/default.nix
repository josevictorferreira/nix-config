{ lib
, pkgs
, config
, username
, ...
}:

let
  cfg = config.jvf.desktop.hyprland.waybar;
in
{
  options.jvf.desktop.hyprland.waybar = {
    enable = lib.mkEnableOption "Wayland bar for Sway and Wlroots based compositors";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure nvim wrapper";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.waybar.enable = true;

    jvf.wrappers.users.${cfg.username}.programs.waybar = {
      packages = [
        pkgs.waybar
      ];
      configs = {
        "waybar" = ./.;
      };
    };
  };
}
