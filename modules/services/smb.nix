{ config, lib, ... }:

let
  cfg = config.jvf.services.smb;
  homeDir = lib.attrByPath [ "users" "users" cfg.username "home" ] "/Users/${cfg.username}" config;
  group = group;
  mntPoint = "${homeDir}/${cfg.name}";
  smbMount = name: username: {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        config.sops.templates."mount-${name}".path
      ];
      RunAtLoad = true;
      StandardErrorPath = "${homeDir}/Library/Logs/mount-${name}.err.log";
      StandardOutPath = "${homeDir}/Library/Logs/mount-${name}.out.log";
      StartInterval = 30;
      UserName = username;
      GroupName = group;
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
  options.jvf.services.smb = {
    enable = lib.mkEnableOption "Enable the mount of the smb share";
    name = lib.mkOption {
      type = lib.types.str;
      example = "Homelab";
      description = "Name of the SMB share. Also used as the group name.";
    };
    isDarwin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Set to true if the system is macOS.";
    };
    username = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Local user to add to the group created with the `name` option.";
    };
    serverAddress = lib.mkOption {
      type = lib.types.str;
      default = "10.10.10.124";
      description = "SMB server hostname or IP address. Must include only the IP and the shared directory.";
    };
    exportedName = lib.mkOption {
      type = lib.types.str;
      description = "Name of the exported SMB share.";
    };
  };

  config = lib.mkIf config.jvf.services.smb.enable {
    launchd.agents = lib.mkIf cfg.isDarwin {
      "${group}-smb" = smbMount cfg.exportedName cfg.username;
    };

    sops.secrets."${group}_smb_username" = {
      owner = cfg.username;
      group = group;
      mode = "0400";
    };

    sops.secrets."${group}_smb_password" = {
      owner = cfg.username;
      group = group;
      mode = "0400";
    };

    sops.templates."nsmb.conf" = {
      path = "${homeDir}/Library/Preferences/nsmb.conf";
      owner = cfg.username;
      group = group;
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
        username=${config.sops.placeholder."${group}_smb_username"}
        password=${config.sops.placeholder."${group}_smb_password"}
      '';
    };

    sops.templates."mount-${group}-smb" = {
      owner = cfg.username;
      group = group;
      mode = "0755";
      content = ''
        #!/bin/sh

        if [ ! -d "${mntPoint}" ]; then
          mkdir -p "${mntPoint}"
          chown ${cfg.username}:${group} "${mntPoint}"
          chmod 2775 "${mntPoint}"
        fi

        /sbin/mount -t smbfs -o ${lib.concatStringsSep "," mntOptions} //${
          config.sops.placeholder."${group}_smb_username"
        }:${
          config.sops.placeholder."${group}_smb_password"
        }@${cfg.serverAddress}/${cfg.exportedName} ${mntPoint}
      '';
    };

    users.groups.${group} = {
      members = [ cfg.username ];
      gid = 2002;
    };
  };
}
