# Aspect: desktop-hyprland-swaync (NixOS only)
# Swaync notification daemon with Hyprland integration.
{ ... }:
{
  flake.modules.nixos.desktop-hyprland-swaync =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.swaync;
    in
    {
      options.jvf.desktop.hyprland.swaync = {
        enable = lib.mkEnableOption "swaync notification daemon";
        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for which to configure swaync wrapper";
        };
      };

      config = lib.mkIf cfg.enable {
        jvf.wrappers.users.${cfg.username}.programs.swaync = {
          packages = [ pkgs.swaynotificationcenter ];
          configs = {
            "swaync" = ./assets/desktop/swaync/.;
          };
        };
      };
    };
}
