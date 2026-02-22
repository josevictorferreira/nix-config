# Aspect: desktop-hyprland-thunar (NixOS only)
# Thunar file manager for Hyprland.
{ ... }:
{
  flake.modules.nixos.desktop-hyprland-thunar =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.thunar;
    in
    {
      options.jvf.desktop.hyprland.thunar = {
        enable = lib.mkEnableOption "Enable Thunar file manager";
        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for which to configure Thunar";
        };
      };

      config = lib.mkIf cfg.enable {
        programs = {
          thunar.enable = true;
          thunar.plugins = [
            pkgs.xfce4-exo
            pkgs.mousepad
            pkgs.thunar-archive-plugin
            pkgs.thunar-volman
            pkgs.tumbler
          ];
        };

        jvf.wrappers.users.${cfg.username}.programs.Thunar = {
          configs = {
            "Thunar" = ../../modules/legacy/_/desktop/hyprland/thunar/.;
          };
        };
      };
    };
}
