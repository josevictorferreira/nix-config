{ lib
, pkgs
, config
, username
, ...
}:

let
  cfg = config.jvf.desktop.hyprland.thunar;
in
{
  options.jvf.desktop.hyprland.thunar = {
    enable = lib.mkEnableOption "Enable Thunar file manager";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure nvim wrapper";
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
        "Thunar" = ./.;
      };
    };
  };
}
