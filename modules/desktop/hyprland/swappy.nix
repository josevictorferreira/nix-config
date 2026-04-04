# Aspect: desktop-hyprland-swappy (NixOS only)
# Wayland native screenshot tool for Hyprland.
_: {
  flake.modules.nixos.desktop-hyprland-swappy =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.swappy;
    in
    {
      options.jvf.desktop.hyprland.swappy = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure swappy";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs.swappy = {
          packages = [
            pkgs.grim
            pkgs.grimblast
            pkgs.hyprshot
            pkgs.swappy
          ];
        };

        jvf.home.users.${cfg.username}.items.".config/swappy" = {
          kind = "dir";
          mode = "copy";
          source = ./assets/swappy;
        };
      };
    };
}
