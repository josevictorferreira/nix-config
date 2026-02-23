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
        enable = lib.mkEnableOption "Rofi application launcher and dmenu replacement";
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure rofi wrapper";
        };
      };

      config = lib.mkMerge [
        # Auto-enable when hyprland desktop is enabled
        (lib.mkIf config.jvf.desktop.hyprland.enable {
          jvf.desktop.hyprland.rofi.enable = lib.mkDefault true;
        })

        (lib.mkIf cfg.enable {
          jvf.wrappers.users.${cfg.username}.programs.rofi = {
            packages = [
              pkgs.rofi
            ];
            configs = {
              "rofi" = ./assets/rofi/.;
            };
          };
        })
      ];
    };
}
