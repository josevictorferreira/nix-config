# Aspect: desktop-hyprland-hypr (NixOS only)
# Hyprland compositor configuration with hypridle, hyprlock, pyprland.
# Configures jvf.wrappers.users for config file management.
{ ... }:
let
  mkOptions =
    { lib, ... }:
    {
      options.jvf.desktop.hyprland.hypr = {
        enable = lib.mkEnableOption "Hyprland with JVF configurations.";

        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for which to configure Hyprland wrapper";
        };
      };
    };

  hyprConfigDir = ./assets/hypr;
in
{
  flake.modules.nixos.desktop-hyprland-hypr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.desktop.hyprland.hypr;
    in
    {
      imports = [ mkOptions ];

      config = lib.mkIf cfg.enable {
        services.hypridle.enable = false;

        programs.hyprland = {
          enable = true;
          xwayland.enable = true;
          package = pkgs.hyprland;
        };

        jvf.wrappers.users.${cfg.username}.programs.hypr = {
          packages = [
            pkgs.hypridle
            pkgs.hyprcursor
            pkgs.hyprlock
            pkgs.pyprland
          ];
          configs = {
            "hypr" = hyprConfigDir;
          };
          postInstall = ''
            echo "Reloading Hyprland..."
            ${config.programs.hyprland.package}/bin/hyprctl reload || true
          '';
        };

        fonts.packages = [
          pkgs.nerd-fonts.jetbrains-mono
        ];
      };
    };
}
