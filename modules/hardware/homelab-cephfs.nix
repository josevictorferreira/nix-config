{ config, lib, pkgs, ... }:

let
  cfg = config.homelab.cephfs;
  inherit (lib) mkEnableOption mkOption types concatStringsSep;
  mons = concatStringsSep "," cfg.monHosts;
in
{
  options.homelab.cephfs = {
    enable = mkEnableOption "Mount CephFS subvolume via fileSystems";
    monHosts = mkOption {
      type = types.listOf types.str;
      example = [ "10.10.10.200:6789" "10.10.10.201:6789" "10.10.10.203:6789" ];
      description = "Ceph MON endpoints host:port.";
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

  config = lib.mkIf cfg.enable {
    boot.supportedFilesystems = [ "ceph" ];
    environment.systemPackages = [ pkgs.ceph ];

    sops.secrets.ceph_client_secret = { };

    users.groups.homelab.gid = 2002;

    fileSystems."${cfg.mountPoint}" =
      let
        secretFile = config.sops.secrets.ceph_client_secret.path;
      in
      lib.mkForce {
        device = "${mons}:${cfg.subvolumePath}";
        fsType = "ceph";
        options = [
          "name=${cfg.clientId}"
          "secretfile=${secretFile}"
          "fs=${cfg.fsName}"
          "_netdev"
          "x-systemd.automount"
          "x-systemd.requires=network-online.target"
          "x-systemd.after=network-online.target"
          "credentials=${secretFile}"
        ];
        neededForBoot = false;
        depends = [ secretFile ];
      };


  };
}

