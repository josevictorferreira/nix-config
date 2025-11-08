{ lib
, pkgs
, config
, username
, ...
}:

let
  cfg = config.jvf.desktop.hyprland.swappy;
in
{
  options.jvf.desktop.hyprland.swappy = {
    enable = lib.mkEnableOption "Wayland native screenshot tool";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure nvim wrapper";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.swappy = {
      packages = [
        pkgs.grim
        pkgs.grimblast
        pkgs.hyprshot
        pkgs.swappy
      ];
      configs = {
        "swappy" = ./.;
      };
    };
  };
}
