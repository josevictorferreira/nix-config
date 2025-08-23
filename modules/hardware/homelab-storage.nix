{ lib, username, isDarwin, ... }:

{
  fileSystems = {
    "/home/${username}/homelab" = lib.mkIf (!isDarwin) {
      device = "10.10.10.150:/homelab";
      fsType = "nfs4";
      options = [ "x-systemd.automount" "noatime" "vers=4.2" ];
    };
  };
}
