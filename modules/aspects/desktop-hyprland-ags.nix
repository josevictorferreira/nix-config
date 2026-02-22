# Aspect: desktop-hyprland-ags (NixOS only)
# AGS - Awesome Hyprland Widgets. Packages + wrapper configs.
{ ... }:
{
  flake.modules.nixos.desktop-hyprland-ags =
    {
      config,
      lib,
      pkgs,
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
          default = "josevictor";
          description = "Username to configure AGS for.";
        };
      };

      config = lib.mkIf cfg.enable {
        jvf.wrappers.users.${cfg.username}.programs.ags = {
          packages = [
            pkgs.ags
          ];
          configs = {
            "ags" = ../legacy/_/desktop/hyprland/ags;
          };
        };
      };
    };
}
