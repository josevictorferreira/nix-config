{
  lib,
  pkgs,
  config,
  username,
  ...
}:

{
  imports = [ ./../services/cephfs.nix ];

  options.jvf.roles.networkStorage = {
    enable = lib.mkEnableOption "Enable homelab storage mount on the home directory.";
  };

  config = lib.mkIf config.jvf.roles.networkStorage.enable {
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
}
