# Aspect: roles-network-storage
# Bundles homelab network storage mounts (SMB on Darwin, CephFS on NixOS).
# Uses isDarwin closure to branch platform config at definition time.
{ ... }:
let
  mkOptions =
    { lib, ... }:
    {
      options.jvf.roles.networkStorage = {
        enable = lib.mkEnableOption "homelab storage mount on the home directory";

        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for network storage.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.roles.networkStorage;
    in
    {
      imports = [ mkOptions ];

      config = lib.mkIf cfg.enable (
        {
          users.users."${cfg.username}".packages = [
            pkgs.rclone
          ];
        }
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
            subvolumePath = "/volumes/nfs-exports/homelab-nfs/5a434804-52fc-4e58-b09f-592a37a16a97";
          };
        }
      );
    };
in
{
  flake.modules.nixos.roles-network-storage = mkConfig { isDarwin = false; };
  flake.modules.darwin.roles-network-storage = mkConfig { isDarwin = true; };
}
