{
  config,
  lib,
  ...
}:

let
  cfg = config.jvf.profiles.homelabStorage;
in
{
  options.jvf.profiles.homelabStorage = {
    enable = lib.mkEnableOption "Enable ";

    isDarwin = lib.mkOption {
      type = lib.types.bool;
      example = false;
      default = false;
      description = "Flag in case the system is a Darwin machine.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      example = "josevictor";
      description = "Username to symlink the storage in the home folder";
    };
  };

  config = lib.mkIf lib.cfg.enable {
    jvf.services.cephFs = lib.mkIf (!cfg.isDarwin) {
      enable = true;
      name = "Homelab";
      mountPoint = "/mnt/homelabfs";
      clusterFsId = "e2f8f1ec-72a4-4b49-a175-058c23a7e84b";
      clientId = "josevictor";
      username = cfg.username;
      monHosts = [
        "10.10.10.200:6789"
        "10.10.10.201:6789"
        "10.10.10.203:6789"
      ];
      fsName = "ceph-filesystem";
      subvolumePath = "/volumes/nfs-exports/homelab-nfs/dfd23da6-d80d-48c7-b568-025ec7badd17";
    };

    jvf.services.smb = lib.mkIf (cfg.isDarwin) {
      enable = true;
      name = "Homelab";
      isDarwin = true;
      username = cfg.username;
      serverAddress = "10.10.10.124";
      exportedName = "homelab-smb";
    };
  };
}
