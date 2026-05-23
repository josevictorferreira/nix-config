# Aspect: roles-network-storage
# Bundles homelab network storage mounts (SMB on Darwin, CephFS on NixOS).
{ self, ... }:
let
  nixosAspects = self.modules.nixos;
  darwinAspects = self.modules.darwin;

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.networkStorage = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for network storage.";
        };
      };
    };

  nixosModule =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.networkStorage;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with nixosAspects; [
        services-cephfs
      ]);

      config = {
        users.users."${cfg.username}".packages = [
          pkgs.rclone
        ];

        jvf.services.cephFs = {
          name = "Homelab";
          mountPoint = "/mnt/homelabfs";
          clusterFsId = "e2f8f1ec-72a4-4b49-a175-058c23a7e84b";
          clientId = "josevictor";
          inherit (cfg) username;
          monHosts = [
            "10.10.10.200:6789"
            "10.10.10.201:6789"
            "10.10.10.203:6789"
          ];
          fsName = "ceph-filesystem";
          subvolumePath = "/volumes/nfs-exports/homelab-nfs/5a434804-52fc-4e58-b09f-592a37a16a97";
        };
      };
    };

  darwinModule =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.networkStorage;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with darwinAspects; [
        services-smb
      ]);

      config = {
        users.users."${cfg.username}".packages = [
          pkgs.rclone
        ];

        jvf.services.smb = {
          name = "Homelab";
          inherit (cfg) username;
          serverAddress = "10.10.10.149";
          exportedName = "homelab-smb";
        };
      };
    };
in
{
  flake.modules.nixos.roles-network-storage = nixosModule;
  flake.modules.darwin.roles-network-storage = darwinModule;
}
