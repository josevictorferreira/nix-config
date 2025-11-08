{ lib
, config
, username
, ...
}:

let
  cfg = config.jvf.desktop.hyprland.gtk3;
in
{
  options.jvf.desktop.hyprland.gtk3 = {
    enable = lib.mkEnableOption "Gtk 3.0 settings.";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure nvim wrapper";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs."gtk-3.0" = {
      packages = [
      ];
      configs = {
        "gtk-3.0" = ./.;
      };
    };
  };
}
