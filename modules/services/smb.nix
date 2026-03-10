# Aspect: services-smb
# Defines jvf.services.smb options for SMB/CIFS share mounting.
# NixOS: empty config (currently unused).
# Darwin: launchd agent, sops secrets/templates, users.groups for SMB mount.
_:
let
  mkSmbOptions =
    { config, lib, ... }:
    {
      options.jvf.services.smb = {
        name = lib.mkOption {
          type = lib.types.str;
          example = "Homelab";
          description = "Name of the SMB share. Also used as the group name.";
        };

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Local user to add to the group created with the `name` option.";
        };

        serverAddress = lib.mkOption {
          type = lib.types.str;
          default = "10.10.10.124";
          description = "SMB server hostname or IP address.";
        };

        exportedName = lib.mkOption {
          type = lib.types.str;
          description = "Name of the exported SMB share.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    { config, lib, ... }:
    let
      cfg = config.jvf.services.smb;

      homeDir = if isDarwin then "/Users/${cfg.username}" else "/home/${cfg.username}";
      group = lib.strings.toLower cfg.name;
      mntPoint = "${homeDir}/${cfg.name}";
      scriptName = "mount-${group}-smb";

      mntOptions = [
        "nosuid"
        "nobrowse"
        "noowners"
        "automounted"
        "nodatacache"
        "nonotification"
      ];

      smbMount =
        { username }:
        {
          serviceConfig = {
            ProgramArguments = [
              "/bin/sh"
              "-c"
              config.sops.templates.${scriptName}.path
            ];
            RunAtLoad = true;
            StandardErrorPath = "${homeDir}/Library/Logs/${scriptName}.err.log";
            StandardOutPath = "${homeDir}/Library/Logs/${scriptName}.out.log";
            StartInterval = 30;
            UserName = username;
            GroupName = group;
          };
        };
    in
    {
      imports = [ mkSmbOptions ];

      config =
        if isDarwin then
          {
            launchd.agents."${group}-smb" = smbMount { inherit (cfg) username; };

            sops.secrets."${group}_smb_username" = {
              owner = cfg.username;
              inherit group;
              mode = "0400";
            };
            sops.secrets."${group}_smb_password" = {
              owner = cfg.username;
              inherit group;
              mode = "0400";
            };

            sops.templates."nsmb.conf" = {
              path = "${homeDir}/Library/Preferences/nsmb.conf";
              owner = cfg.username;
              inherit group;
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

            sops.templates.${scriptName} = {
              owner = cfg.username;
              inherit group;
              mode = "0755";
              content = ''
                #!/bin/sh
                if [ ! -d "${mntPoint}" ]; then
                  mkdir -p "${mntPoint}"
                  chown ${cfg.username}:${group} "${mntPoint}"
                  chmod 2775 "${mntPoint}"
                fi

                /sbin/mount | /usr/bin/grep -q " on ${mntPoint} " && exit 0

                /sbin/mount_smbfs -f 0644 -d 0775 -o ${lib.concatStringsSep "," mntOptions} \
                  //${config.sops.placeholder."${group}_smb_username"}:${
                    config.sops.placeholder."${group}_smb_password"
                  }@${cfg.serverAddress}/${cfg.exportedName} \
                  ${mntPoint}
              '';
            };

            users.groups.${group} = {
              members = [ cfg.username ];
              gid = 2002;
            };
          }
        else
          { };
    };
in
{
  flake.modules.nixos.services-smb = mkConfig { isDarwin = false; };
  flake.modules.darwin.services-smb = mkConfig { isDarwin = true; };
}
