# Aspect: desktop-hyprland-kvantum (NixOS only)
# Kvantum theme engine for Qt apps in Hyprland.
_: {
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
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure Kvantum";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.Kvantum.packages = [
          pkgs.libsForQt5.qtstyleplugin-kvantum
          pkgs.qt6Packages.qtstyleplugin-kvantum
        ];
        jvf.home.users.${cfg.username}.items.".config/Kvantum" = {
          kind = "dir";
          mode = "copy";
          source = ./assets/kvantum;
        };
      };
    };
}
