{ lib, config, pkgs, ... }:
with lib;

let
  cfg = config.homelab.nfs;

  optsList = [
  ] ++ lib.optionals cfg.resvport [ "resvport" ] ++ cfg.extraOptions;

  optsText = lib.concatStringsSep "," optsList;

  fstabLine = "${cfg.server}:${cfg.remotePath} ${cfg.mountPoint} nfs ${optsText} 0 0";
in
{
  options.homelab.nfs = {
    enable = mkEnableOption "Homelab NFSv4 automount on macOS";
    username = mkOption { type = types.str; example = "ze"; description = "Existing macOS username to add to homelab group."; };

    server = mkOption { type = types.str; example = "nas.lan"; description = "NFS server hostname or IP."; };
    remotePath = mkOption { type = types.str; example = "/homelab-nfs"; description = "Remote export path on the NFS server."; };
    mountPoint = mkOption { type = types.str; default = "/Volumes/homelab-nfs"; description = "Local mount point."; };

    nfsVersion = mkOption { type = types.enum [ "4" "4.1" "4.2" ]; default = "4.2"; };
    rsize = mkOption { type = types.int; default = 1048576; };
    wsize = mkOption { type = types.int; default = 1048576; };
    timeo = mkOption { type = types.int; default = 600; description = "Tenths of a second."; };
    retrans = mkOption { type = types.int; default = 2; };
    resvport = mkOption { type = types.bool; default = false; description = "Enable if your NAS requires reserved ports."; };
    extraOptions = mkOption { type = types.listOf types.str; default = [ ]; description = "Any extra raw mount options."; };
  };

  config = mkIf cfg.enable {
    users.groups.homelab = {
      gid = 2002;
      members = [ cfg.username ];
    };

    system.activationScripts.homelab-nfs-automount-reload.text = ''
      /usr/sbin/automount -cv >/dev/null 2>&1 || true
    '';

    system.activationScripts.homelab-nfs-init.text = ''
      set -eu
      mkdir -p "${cfg.mountPoint}"
      chgrp -f homelab "${cfg.mountPoint}" || true
      chmod 775 "${cfg.mountPoint}" || true
    '';

    system.activationScripts.homelab-fstab-append.text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      file="/etc/fstab"
      line='${cfg.server}:${cfg.remotePath} ${cfg.mountPoint} nfs ${optsText} 0 0'
      touch "$file"
      if ! grep -Fqx -- "$line" "$file"; then
        cp -a "$file" "$file.nixbak.$(date +%Y%m%d%H%M%S)" || true
        printf '%s\n' "$line" >> "$file"
      fi
    '';

    launchd.daemons.homelab-nfs-mount = {
      serviceConfig = {
        Label = "org.nix-darwin.homelab-nfs-mount";
        ProgramArguments = [
          "/sbin/mount"
          "-t"
          "nfs"
          "-o"
          "${optsText}"
          "${cfg.server}:${cfg.remotePath}"
          "${cfg.mountPoint}"
        ];
        RunAtLoad = true;
      };
    };

  };
}
