{
  lib,
  pkgs,
  config,
  username,
  inputs,
  ...
}:

let
  cfg = config.jvf.desktop.hyprland.hypr;
in
{
  options.jvf.desktop.hyprland.hypr = {
    enable = lib.mkEnableOption "Hyprland with JVF configurations.";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure nvim wrapper";
    };
  };

  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      xwayland.enable = true;
      extraConfig = builtins.readFile ./hyprland.conf;
    };

    jvf.wrappers.users.${cfg.username}.programs.hypr = {
      packages = [
        pkgs.hypridle
        pkgs.hyprcursor
        pkgs.hyprlock
        pkgs.pyprland
      ];
      configs = {
        "hypr" = ./.;
      };
    };
  };
}
