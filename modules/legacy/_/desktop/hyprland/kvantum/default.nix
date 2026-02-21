{ lib
, pkgs
, config
, username
, ...
}:

let
  cfg = config.jvf.desktop.hyprland.kvantum;
in
{
  options.jvf.desktop.hyprland.kvantum = {
    enable = lib.mkEnableOption "Generate a 16 color schema based on an image.";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure nvim wrapper";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.Kvantum = {
      packages = [
        pkgs.libsForQt5.qtstyleplugin-kvantum
        pkgs.qt6Packages.qtstyleplugin-kvantum
      ];
      configs = {
        "Kvantum" = ./.;
      };
    };
  };
}
