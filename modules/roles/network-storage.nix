{
  lib,
  config,
  system,
  username,
  ...
}:

let
  cfg = config.jvf.roles.networkStorage;

  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  imports =
    [ ]
    ++ (if isDarwin then [ ./../services/smb.nix ] else [ ])
    ++ (if !isDarwin then [ ./../services/cephfs.nix ] else [ ]);

  options.jvf.roles.networkStorage = {
    enable = lib.mkEnableOption "Enable homelab storage mount on the home directory.";

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for network storage.";
    };
  };

  config = lib.mkIf cfg.enable (
    { }
    // lib.optionalAttrs isDarwin {
      jvf.services.smb = {
        enable = true;
        name = "Homelab";
        username = cfg.username;
        serverAddress = "10.10.10.129";
        exportedName = "homelab-smb";
      };
    }
    // lib.optionalAttrs (!isDarwin) {
      jvf.services.cephFs = {
        enable = false;
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
    }
  );
}
