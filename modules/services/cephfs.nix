# Aspect: services-cephfs (NixOS only)
# Mounts a CephFS subvolume via native ceph + bindfs for user-friendly access.
# Darwin does not support CephFS.
{ ... }:
{
  flake.modules.nixos.services-cephfs =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.services.cephFs;
      mons = lib.concatStringsSep "," cfg.monHosts;
      homeDir = "/home/${cfg.username}";
    in
    {
      options.jvf.services.cephFs = {
        name = lib.mkOption {
          type = lib.types.str;
          example = "Homelab";
          description = "The name of the cephfs folder. It will be used as the name of the symlinked folder. Also it will be used as the group created to handle RWX operations on the folder.";
        };

        monHosts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "10.10.10.200:6789"
            "10.10.10.201:6789"
            "10.10.10.203:6789"
          ];
          description = "Ceph MON endpoints host:port.";
        };

        clusterFsId = lib.mkOption {
          type = lib.types.str;
          default = "";
          example = "a0b1c2d3-e4f5-6789-abcd-ef0123456789";
          description = "Ceph cluster FSID.";
        };

        fsName = lib.mkOption {
          type = lib.types.str;
          default = "cephfs";
          description = "CephFS name.";
        };

        clientId = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "CephX client id (without the 'client.' prefix).";
        };

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Local user to add to the 'homelab' group.";
        };

        subvolumePath = lib.mkOption {
          type = lib.types.str;
          default = "";
          example = "/volumes/nfs-exports/homelab-nfs/dfd23da6-d80d-48c7-b568-025ec7badd17";
          description = "Absolute path to the subvolume on CephFS.";
        };

        mountPoint = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/homelabfs";
          description = "Local mountpoint.";
        };
      };

      config = {
        environment.systemPackages = [ pkgs.ceph-client ];

        system.fsPackages = [ pkgs.bindfs ];

        sops.secrets.ceph_client_keyring = {
          path = "/etc/ceph/ceph.keyring";
          owner = cfg.username;
          group = lib.strings.toLower cfg.name;
          mode = "0400";
        };
        sops.secrets.ceph_client_secret = {
          path = "/run/secrets/ceph_client_secret";
          owner = cfg.username;
          group = lib.strings.toLower cfg.name;
          mode = "0400";
        };

        environment.etc."ceph/ceph.conf".text = ''
          [global]
          fsid = ${cfg.clusterFsId}
          mon_host = ${mons}
        '';

        users = {
          groups = {
            ${lib.strings.toLower cfg.name}.gid = 2002;
          };
          users."${cfg.username}" = {
            packages = [
              pkgs.ceph-client
            ];
            extraGroups = lib.mkAfter [ "${lib.strings.toLower cfg.name}" ];
          };
        };

        fileSystems."${cfg.mountPoint}" =
          let
            keyringFile = config.sops.secrets.ceph_client_keyring.path;
            secretFile = config.sops.secrets.ceph_client_secret.path;
          in
          {
            device = "${mons}:${cfg.subvolumePath}";
            fsType = "ceph";
            options = [
              "name=${cfg.clientId}"
              "secretfile=${secretFile}"
              "fs=${cfg.fsName}"
              "_netdev"
              "x-systemd.automount"
              "x-systemd.idle-timeout=60"
              "x-systemd.requires=network-online.target"
              "x-systemd.after=network-online.target"
            ];
            neededForBoot = false;
            depends = [
              keyringFile
              secretFile
              "/etc/ceph/ceph.conf"
            ];
          };

        fileSystems."${homeDir}/${cfg.name}" = {
          device = cfg.mountPoint;
          fsType = "fuse.bindfs";
          options = [
            "force-user=2002"
            "force-group=2002"
            "perms=g+w:u+rwX:g+rwX:o=rD"
            "create-for-user=2002"
            "create-for-group=2002"
            "create-with-perms=u=rwX:g=rwXs:o=rx"
            "chown-ignore"
            "chgrp-ignore"
            "allow_other"
            "x-systemd.automount"
            "x-systemd.idle-timeout=60"
            "x-systemd.requires=network-online.target"
            "x-systemd.after=network-online.target"
            "noauto"
            "nofail"
          ];
          neededForBoot = false;
          depends = [ cfg.mountPoint ];
        };

        systemd.tmpfiles.rules = [
          "d ${homeDir}/${cfg.name} 0755 ${cfg.username} users -"
        ];
      };
    };
}
