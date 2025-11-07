{ lib
, pkgs
, config
, systemd
, username
, ...
}:

let
  cfg = config.jvf.desktop.hyprland.swaync;
in
{
  options.jvf.desktop.hyprland.swaync = {
    enable = lib.mkEnableOption "swaync notification daemon";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to configure nvim wrapper";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.wrappers.users.${cfg.username}.programs.swaync = {
      packages = [ pkgs.swaynotificationcenter ];
      command = "${pkgs.swaynotificationcenter}/bin/swaync";
    };

    # Start swaync notification daemon automatically via systemd user service
    systemd.user.services.swaync = {
      description = "Sway Notification Center";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
        Restart = "on-failure";
      };
    };
  };
}
