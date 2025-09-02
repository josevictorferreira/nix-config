{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.homelab.smb;
  smbMount = name: username: {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh" "-c" config.sops.templates."mount-${name}".path
      ];
      RunAtLoad = true;
      StandardErrorPath = "/Users/${username}/Library/Logs/mount-${name}.err.log";
      StandardOutPath = "/Users/${username}/Library/Logs/mount-${name}.out.log";
      StartInterval = 30;
      UserName = username;
      GroupName = "homelab";
    };
  };
  mntOptions = [
    "nosuid"
    "nobrowse"
    "noowners"
    "nosuid"
    "automounted"
    "nodatacache"
    "nomdatacache"
    "nonotification"
    "-f=0644"
    "-d=0775"
  ];
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
    serverAddress = mkOption {
      type = types.str;
      default = "10.10.10.124";
      description = "SMB server hostname or IP address. Must include only the IP and the shared directory.";
    };
    exportedName = mkOption {
      type = types.str;
      default = "homelab-smb";
      description = "Name of the exported SMB share.";
    };
    mountPoint = mkOption {
      type = types.str;
      default = "/mnt/Homelab";
      description = "Local mountpoint.";
    };
  };

  config = lib.mkIf config.homelab.smb.enable {
    launchd.agents = lib.mkIf cfg.isDarwin {
      "homelab-smb" = smbMount cfg.exportedName cfg.username;
    };

    sops.secrets.homelab_smb_username = {
      owner = cfg.username;
      group = "homelab";
      mode = "0400";
    };

    sops.secrets.homelab_smb_password = {
      owner = cfg.username;
      group = "homelab";
      mode = "0400";
    };

    sops.templates."nsmb.conf" = {
      path = "/Users/${cfg.username}/Library/Preferences/nsmb.conf";
      owner = cfg.username;
      group = "homelab";
      mode = "0600";
      content = ''
        [default]
        minauth=none
        streams=yes
        signing_required=no
        notify_off=yes
        dir_cache_off=yes
        dir_cache_async_cnt=0
        dir_cache_max_cnt=0
        dir_cache_max=0
        dir_cache_min=0

        [${cfg.serverAddress}]
        username=${config.sops.placeholder.homelab_smb_username}
        password=${config.sops.placeholder.homelab_smb_password}
      '';
    };

    sops.templates."mount-homelab-smb" = {
      owner = cfg.username;
      group = "homelab";
      mode = "0755";
      content = ''
        #!/bin/sh

        if [ ! -d "${cfg.mountPoint}" ]; then
          mkdir -p "${cfg.mountPoint}"
          chown ${cfg.username}:homelab "${cfg.mountPoint}"
          chmod 2775 "${cfg.mountPoint}"
        fi

        /sbin/mount -t smbfs -o ${lib.concatStringsSep "," mntOptions} //${config.sops.placeholder.homelab_smb_username}:${config.sops.placeholder.homelab_smb_password}@${cfg.serverAddress}/${cfg.exportedName} ${cfg.mountPoint}
      '';
    };

    users.groups.homelab = {
      members = [ cfg.username ];
      gid = 2002;
    };
  };
}
