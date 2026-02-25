# Aspect: desktop-hyprland-wallust (NixOS only)
# Wallust - Generate a 16 color schema based on an image.
_:
{
  flake.modules.nixos.desktop-hyprland-wallust =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.wallust;
    in
    {
      options.jvf.desktop.hyprland.wallust = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure wallust";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.wallust = {
          packages = [
            pkgs.wallust
            pkgs.swww
          ];
          configs = {
            "wallust" = ./assets/wallust;
          };
        };
      };
    };
}
