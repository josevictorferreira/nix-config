{ lib, username, isDarwin, ... }:

{
  fileSystems = {
    "/home/${username}/homelab" = lib.mkIf (!isDarwin) {
      device = "10.10.10.150:/homelab";
      fsType = "nfs4";
      options = [ "vers=4.2" "rw" "hard" "noatime" "timeo=600" "actimeo=60" "retrans=2" "x-systemd.automount" ];
    };
  };
}
