{ lib, config, username, isDarwin, ... }:

let mnt = "/mnt/homelab"; in
{
  fileSystems = {
    "${mnt}" = lib.mkIf (!isDarwin) {
      device = "10.10.10.150:/homelab";
      fsType = "nfs4";
      options = [ "vers=4.2" "rw" "hard" "noatime" "timeo=600" "actimeo=60" "retrans=2" "x-systemd.automount" ];
    };
  };

  system.activationScripts.homelabLink = ''
    install -d -o ${username} -g users /home/${username}
    ln -snf ${mnt} /home/${username}
    chown -h ${username}:users /home/${username}/homelab
  '';

  users.groups.homelab.gid = 2002;
  users.users.${username}.extraGroups = lib.mkAfter [ "homelab" ];
}
