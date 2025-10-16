{ config
, lib
, isDarwin
, username
, ...
}:

let
  cfg = config.jvf.profiles.homelabStorage;
  profileOptions = {
    enable = lib.mkEnableOption "Enable homelab storage mount on the home directory.";
  };
  darwinModule = {
    imports = [ ./../services/smb.nix ];

    options.jvf.profiles.homelabStorage = profileOptions;

    config = lib.mkIf (cfg.enable) {
      jvf.services.smb = {
        enable = true;
        name = "Homelab";
        username = username;
        serverAddress = "10.10.10.124";
        exportedName = "homelab-smb";
      };
    };
  };
  defaultModule = {
    imports = [ ./../services/cephfs.nix ];

    options.jvf.profiles.homelabStorage = profileOptions;

    config = lib.mkIf (cfg.enable) {
      jvf.services.cephFs = {
        enable = true;
        name = "Homelab";
        mountPoint = "/mnt/homelabfs";
        clusterFsId = "e2f8f1ec-72a4-4b49-a175-058c23a7e84b";
        clientId = "josevictor";
        username = username;
        monHosts = [
          "10.10.10.200:6789"
          "10.10.10.201:6789"
          "10.10.10.203:6789"
        ];
        fsName = "ceph-filesystem";
        subvolumePath = "/volumes/nfs-exports/homelab-nfs/dfd23da6-d80d-48c7-b568-025ec7badd17";
      };
    };
  };
in
if isDarwin then darwinModule else defaultModule
