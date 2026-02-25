# Aspect: desktop-hyprland-wlogout (NixOS only)
# Wlogout - A Wayland logout menu.
_:
{
  flake.modules.nixos.desktop-hyprland-wlogout =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.wlogout;
    in
    {
      options.jvf.desktop.hyprland.wlogout = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure wlogout";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.wlogout = {
          packages = [
            pkgs.wlogout
          ];
          configs = {
            "wlogout" = ./assets/wlogout;
          };
        };
      };
    };
}
