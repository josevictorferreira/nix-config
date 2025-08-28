{ lib, username, isDarwin, ... }:

let mnt = "/mnt/homelab-nfs"; in
{
  fileSystems = {
    "${mnt}" = lib.mkIf (!isDarwin) {
      device = "10.10.10.150:/homelab-nfs";
      fsType = "nfs4";
      options = [ "minorversion=2" "sec=sys" "hard" "noresvport" "nconnect=8" "_netdev" "noatime" "timeo=600" "actimeo=60" "retrans=2" "x-systemd.automount" ];
    };
  };

  system.activationScripts.homelabLink = ''
    install -d -o ${username} -g users /home/${username}
    ln -snf ${mnt} /home/${username}
    chown -h ${username}:users /home/${username}/homelab-nfs
  '';

  users.groups.homelab.gid = 2002;

  users.users.${username}.extraGroups = lib.mkAfter [ "homelab" ];
}
