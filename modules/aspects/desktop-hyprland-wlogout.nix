# Aspect: desktop-hyprland-wlogout (NixOS only)
# Wlogout - A Wayland logout menu.
{ ... }:
{
  flake.modules.nixos.desktop-hyprland-wlogout =
    {
      config,
      lib,
      pkgs,
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
          default = "josevictor";
          description = "Username for which to configure wlogout";
        };
      };

      config = lib.mkIf cfg.enable {
        jvf.wrappers.users.${cfg.username}.programs.wlogout = {
          packages = [
            pkgs.wlogout
          ];
          configs = {
            "wlogout" = ./assets/desktop/wlogout;
          };
        };
      };
    };
}
