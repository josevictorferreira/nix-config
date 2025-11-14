{ config, lib, pkgs, ... }:

let
  cfg = config.jvf.system.security;
in
{
  options.jvf.system.security = {
    enable = lib.mkEnableOption "system security configuration" // {
      description = ''
        Whether to enable system security configuration.
        Configures:
        - Realtime kernel scheduling support (rtkit)
        - Polkit for system-level permission management
        - SSH daemon for remote access
        - PAM services for security
        - GNOME keyring integration
      '';
    };

    enableSsh = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable SSH daemon for remote access.";
    };

    enableRtkit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable RealtimeKit for realtime process scheduling.";
    };

    enablePolkit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable PolicyKit for privilege management.";
    };

    enableGnomeKeyring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GNOME keyring for credential storage.";
    };

    enableFwupd = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable firmware updates via fwupd.";
    };
  };

  config = lib.mkIf cfg.enable {
    security = {
      rtkit.enable = cfg.enableRtkit;
      polkit.enable = cfg.enablePolkit;
    };

    services.openssh = lib.mkIf cfg.enableSsh {
      enable = true;
    };

    services.gnome.gnome-keyring = lib.mkIf cfg.enableGnomeKeyring {
      enable = true;
    };

    services.fwupd = lib.mkIf cfg.enableFwupd {
      enable = true;
    };
  };
}
