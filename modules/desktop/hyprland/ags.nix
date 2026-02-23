# Aspect: desktop-hyprland-ags (NixOS only)
# AGS - Awesome Hyprland Widgets. Packages + wrapper configs.
{ ... }:
{
  flake.modules.nixos.desktop-hyprland-ags =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.ags;
    in
    {
      options.jvf.desktop.hyprland.ags = {

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username to configure AGS for.";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.ags = {
          packages = [
            pkgs.ags
          ];
          configs = {
            "ags" = ./assets/ags;
          };
        };
      };
    };
}
