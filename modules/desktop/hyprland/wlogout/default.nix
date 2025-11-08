{
  lib,
  pkgs,
  config,
  username,
  ...
}:

let
  cfg = config.jvf.desktop.hyprland.wlogout;
in
{
  options.jvf.desktop.hyprland.wlogout = {
    enable = lib.mkEnableOption "A Wayland logout menu";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure nvim wrapper";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.wlogout = {
      packages = [
        pkgs.wlogout
      ];
      configs = {
        "wlogout" = ./.;
      };
    };
  };
}
