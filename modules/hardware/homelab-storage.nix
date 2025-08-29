{ lib, username, isDarwin, ... }:

let mnt = "/home/${username}/homelab-nfs"; in
{
  fileSystems = {
    "${mnt}" = lib.mkIf (!isDarwin) {
      device = "10.10.10.150:/homelab-nfs";
      fsType = "nfs4";
      options = [ "vers=4.2" "sec=sys" "hard" "noresvport" "nconnect=8" "_netdev" "rsize=1048576" "wsize=1048576" "async" "noatime" "timeo=600" "actimeo=60" "retrans=2" "x-systemd.automount" ];
    };
  };

  users.groups.homelab.gid = 2002;

  users.users.${username}.extraGroups = lib.mkAfter [ "homelab" ];
}
