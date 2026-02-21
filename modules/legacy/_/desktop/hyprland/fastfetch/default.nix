{ lib
, config
, username
, ...
}:

let
  cfg = config.jvf.desktop.hyprland.fastfetch;
in
{
  options.jvf.desktop.hyprland.fastfetch = {
    enable = lib.mkEnableOption "Fastfetch hyprland and nixos settings.";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure nvim wrapper";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.fastfetch = {
      packages = [
      ];
      configs = {
        fastfetch = ./.;
      };
    };
  };
}
