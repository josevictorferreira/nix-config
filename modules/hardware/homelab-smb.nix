{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkOption types concatStringsSep;
  cfg = config.homelab.smb;
  mountOptions = [
    "file_mode=0644"
    "dir_mode=0775"
    "nobrowse"
    "automounted"
    "nonotification"
    "nopassprompt"
  ];
  smbMount = name: device: mountPoint: {
    serviceConfig = {
      ProgramArguments = [
        "/sbin/mount_smbfs"
        "-o ${concatStringsSep "," (mountOptions ++ cfg.additionalMountOptions)}" 
        device
        mountPoint
      ];
      RunAtLoad = true;
      StandardErrorPath = "/var/log/mount-${name}.err.log";
      StandarrdOutPath = "/var/log/mount-${name}.out.log";
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
    additionalMountOptions = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional mount options to pass to mount_smbfs.";
    };
  };

  config = lib.mkIf config.homelab.smb.enable {
    launchd.daemons = lib.mkId cfg.isDarwin {
      "homelab-smb" = smbMount "homelab-smb" cfg.server cfg.mountPoint;
    };

    sops.secrets.smb_credentials = lib.mkIf cfg.isDarwin {
      path = "/Users/${cfg.username}/Library/Preferences/nsmb.conf";
      mode = "0600";
      user = cfg.username;
      group = "homelab";
    };

    users.groups.homelab = {
      members = [ cfg.username ];
      gid = 2002;
    };
  };
}
