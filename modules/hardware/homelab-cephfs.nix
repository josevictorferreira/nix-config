{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption types concatStringsSep;
  mons = concatStringsSep "," cfg.monHosts;
  cfg = config.homelab.cephfs;
in
{
  options.homelab.cephfs = {
    enable = mkEnableOption "Mount CephFS subvolume via fileSystems";
    monHosts = mkOption {
      type = types.listOf types.str;
      example = [ "10.10.10.200:6789" "10.10.10.201:6789" "10.10.10.203:6789" ];
      description = "Ceph MON endpoints host:port.";
    };
    clusterFsId = mkOption {
      type = types.str;
      example = "a0b1c2d3-e4f5-6789-abcd-ef0123456789";
      description = "Ceph cluster FSID.";
    };
    fsName = mkOption {
      type = types.str;
      default = "cephfs";
      description = "CephFS name.";
    };
    clientId = mkOption {
      type = types.str;
      default = "josevictor";
      description = "CephX client id (without the 'client.' prefix).";
    };
    username = mkOption {
      type = types.str;
      default = "";
      description = "Local user to add to the 'homelab' group.";
    };
    subvolumePath = mkOption {
      type = types.str;
      example = "/volumes/nfs-exports/homelab-nfs/dfd23da6-d80d-48c7-b568-025ec7badd17";
      description = "Absolute path to the subvolume on CephFS.";
    };
    mountPoint = mkOption {
      type = types.str;
      default = "/mnt/homelabfs";
      description = "Local mountpoint.";
    };
  };

  config = lib.mkIf config.homelab.cephfs.enable {
    environment.systemPackages = [ pkgs.ceph-client ];
    system.fsPackages = [ pkgs.bindfs ];

    sops.secrets.ceph_client_keyring = {
      path = "/etc/ceph/ceph.keyring";
    };

    sops.secrets.ceph_client_secret = { };

    environment.etc."ceph/ceph.conf".text = ''
      [global]
      fsid = ${cfg.clusterFsId}
      mon_host = ${mons}
    '';

    users.users."${cfg.username}".extraGroups = lib.mkAfter [ "homelab" ];

    users.groups.homelab.gid = 2002;

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
        depends = [ keyringFile secretFile "/etc/ceph/ceph.conf" ];
      };

    fileSystems."/home/${cfg.username}/Homelab" = {
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
      "d /home/${cfg.username}/Homelab 0755 ${cfg.username} users -"
    ];

  };
}
