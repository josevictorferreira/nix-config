# Aspect: desktop-hyprland-swappy (NixOS only)
# Wayland native screenshot tool for Hyprland.
{ ... }:
{
  flake.modules.nixos.desktop-hyprland-swappy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.swappy;
    in
    {
      options.jvf.desktop.hyprland.swappy = {
        enable = lib.mkEnableOption "Wayland native screenshot tool";
        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for which to configure swappy";
        };
      };

      config = lib.mkIf cfg.enable {
        jvf.wrappers.users.${cfg.username}.programs.swappy = {
          packages = [
            pkgs.grim
            pkgs.grimblast
            pkgs.hyprshot
            pkgs.swappy
          ];
          configs = {
            "swappy" = ../../modules/legacy/_/desktop/hyprland/swappy/.;
          };
        };
      };
    };
}
