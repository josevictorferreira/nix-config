# Aspect: desktop-hyprland-rofi (NixOS only)
# Rofi application launcher with Hyprland theming.
{ ... }:
{
  flake.modules.nixos.desktop-hyprland-rofi =
    { lib
    , config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.rofi;
    in
    {
      options.jvf.desktop.hyprland.rofi = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure rofi wrapper";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.rofi = {
          packages = [
            pkgs.rofi
          ];
          configs = {
            "rofi" = ./assets/rofi/.;
          };
        };
      };
    };
}
