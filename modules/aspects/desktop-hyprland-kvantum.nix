# Aspect: desktop-hyprland-kvantum (NixOS only)
# Kvantum theme engine for Qt apps in Hyprland.
{ ... }:
{
  flake.modules.nixos.desktop-hyprland-kvantum =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.kvantum;
    in
    {
      options.jvf.desktop.hyprland.kvantum = {
        enable = lib.mkEnableOption "Generate a 16 color schema based on an image.";
        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for which to configure Kvantum";
        };
      };

      config = lib.mkIf cfg.enable {
        jvf.wrappers.users.${cfg.username}.programs.Kvantum = {
          packages = [
            pkgs.libsForQt5.qtstyleplugin-kvantum
            pkgs.qt6Packages.qtstyleplugin-kvantum
          ];
          configs = {
            "Kvantum" = ../assets/desktop/kvantum;
          };
        };
      };
    };
}
