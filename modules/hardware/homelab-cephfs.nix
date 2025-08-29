{ lib, username, pkgs, ... }:

let
  cephUser = "client.${username}";
  monHosts = [
    "10.10.10.200:6789"
    "10.10.10.201:6789"
    "10.10.10.203:6789"
  ];
  monList = lib.concatStringsSep "," monHosts;

  mountPoint = "/mnt/homelab-cephfs";
  secretPath = "/run/secrets/ceph/client.homelab.secret";
in
{
  boot.supportedFilesystems = [ "ceph" ];

  users.groups.homelab.gid = 2002;

  users.users.${username}.extraGroups = lib.mkAfter [ "homelab" ];

  systemd.tmpfiles.rules = [
    "d ${mountPoint} 0755 root root -"
  ];

  sops.secrets."ceph_client_secret" = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  environment = {
    systemPackages = with pkgs; [
      ceph
    ];
  };

  fileSystems."${mountPoint}" = {
    device = "${monList}:/";
    fsType = "ceph";
    options = [
      "name=${cephUser}"
      "secretfile=${secretPath}"
      "noatime"
      "_netdev"
      "readdirplus"
      "dentry_timeout=10"
      "attribute_timeout=10"
      "x-systemd.automount"
      "x-systemd.idle-timeout=300s"
    ];
  };

  system.activationScripts.homelab-cephfs-mount.text = ''
    set -eu

    if mountpoint -q "${mountPoint}"; then
      # Symlink (force replace)
      ln -sfn "${mountPoint}" "/home/${username}/homelab-cephfs"

      # Fix ownership if needed
      if [ "$(stat -c %U ${mountPoint})" != "${username}" ]; then
        chown -R ${username}:homelab "${mountPoint}" || true
      fi

      chmod 700 "${mountPoint}" || true
    else
      echo "Warning: ${mountPoint} is not mounted, skipping activation adjustments."
    fi
  '';
}

