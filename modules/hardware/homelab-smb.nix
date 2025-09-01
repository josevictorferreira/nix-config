{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkOption types concatStringsSep;
  cfg = config.homelab.smb;
  smbMount = name: device: mountPoint: {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh" "-c"
        ''
          mkdir -p "${cfg.mountPoint}"
          chown ${cfg.username}:homelab "${cfg.mountPoint}" || true
          chmod 2775 "${cfg.mountPoint}" || true
          /sbin/mount_smbfs -N ${cfg.server} ${cfg.mountPoint}
        ''
      ];
      RunAtLoad = true;
      StandardErrorPath = "/var/log/mount-${name}.err.log";
      StandardOutPath = "/var/log/mount-${name}.out.log";
      StartInterval = 30;
    };
  };
in
{
  options.homelab.smb = {
    enable = mkEnableOption "Mount homelab smb share";
    isDarwin = mkOption {
      type = types.bool;
      default = false;
      description = "Set to true if the system is macOS.";
    };
    username = mkOption {
      type = types.str;
      default = "";
      description = "Local user to add to the 'homelab' group.";
    };
    server = mkOption {
      type = types.str;
      default = "//username:password@10.10.10.124/homelab";
      description = "SMB server hostname or IP address. Must include the // prefix.";
    };
    mountPoint = mkOption {
      type = types.str;
      default = "/mnt/homelab-smb";
      description = "Local mountpoint.";
    };
  };

  config = lib.mkIf config.homelab.smb.enable {
    launchd.daemons = lib.mkIf cfg.isDarwin {
      "homelab-smb" = smbMount "homelab-smb" cfg.server cfg.mountPoint;
    };

    sops.secrets.smb_credentials = lib.mkIf cfg.isDarwin {
      path = "/Users/${cfg.username}/Library/Preferences/nsmb.conf";
      mode = "0600";
      owner = cfg.username;
      group = "homelab";
    };

    system.activationScripts.homelab-smb = lib.stringAfter [ "users" ] ''
      if [ ! -d "${cfg.mountPoint}" ]; then
        mkdir -p "${cfg.mountPoint}"
        chown ${cfg.username}:homelab "${cfg.mountPoint}"
        chmod 2775 "${cfg.mountPoint}"
      fi
    '';

    users.groups.homelab = {
      members = [ cfg.username ];
      gid = 2002;
    };
  };
}
