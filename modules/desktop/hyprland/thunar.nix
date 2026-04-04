# Aspect: desktop-hyprland-thunar (NixOS only)
# Thunar file manager for Hyprland.
_: {
  flake.modules.nixos.desktop-hyprland-thunar =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.thunar;
    in
    {
      options.jvf.desktop.hyprland.thunar = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure Thunar";
        };
      };

      config = {
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

        jvf.home.users.${cfg.username}.items.".config/Thunar" = {
          kind = "dir";
          mode = "copy";
          source = ./assets/thunar;
        };
      };
    };
}
