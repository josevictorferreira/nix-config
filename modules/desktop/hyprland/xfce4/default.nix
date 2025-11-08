{
  lib,
  pkgs,
  config,
  username,
  ...
}:

let
  cfg = config.jvf.desktop.hyprland.xfce4;
in
{
  options.jvf.desktop.hyprland.xfce4 = {
    enable = lib.mkEnableOption "Enable xfce4 file manager";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure nvim wrapper";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.xfce4 = {
      configs = {
        "xfce4" = ./.;
      };
    };
  };
}
