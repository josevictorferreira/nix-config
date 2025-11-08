{
  lib,
  pkgs,
  config,
  username,
  ...
}:

let
  cfg = config.jvf.desktop.hyprland.wallust;
in
{
  options.jvf.desktop.hyprland.wallust = {
    enable = lib.mkEnableOption "Generate a 16 color schema based on an image.";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure nvim wrapper";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.wallust = {
      packages = [
        pkgs.wallust
        pkgs.swww
      ];
      configs = {
        "wallust" = ./.;
      };
    };
  };
}
