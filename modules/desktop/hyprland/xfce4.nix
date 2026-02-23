# Aspect: desktop-hyprland-xfce4 (NixOS only)
# XFCE4 settings for Hyprland.
{ ... }:
{
  flake.modules.nixos.desktop-hyprland-xfce4 =
    { config, lib, ... }:
    let
      cfg = config.jvf.desktop.hyprland.xfce4;
    in
    {
      options.jvf.desktop.hyprland.xfce4 = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure xfce4";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.xfce4 = {
          configs = {
            "xfce4" = ./assets/xfce4;
          };
        };
      };
    };
}
