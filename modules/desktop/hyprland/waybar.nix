# Aspect: desktop-hyprland-waybar (NixOS only)
# Waybar status bar for Hyprland. Packages + wrapper configs + fonts.
_:
{
  flake.modules.nixos.desktop-hyprland-waybar =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.waybar;
    in
    {
      options.jvf.desktop.hyprland.waybar = {

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for which to configure waybar wrapper";
        };
      };

      config = {
        programs.waybar.enable = true;

        jvf.wrappers.users.${cfg.username}.programs.waybar = {
          packages = [
            pkgs.waybar
          ];
          configs = {
            "waybar" = ./assets/waybar/.;
          };
        };

        fonts.packages = [
          pkgs.nerd-fonts.jetbrains-mono
          pkgs.font-awesome
        ];
      };
    };
}
