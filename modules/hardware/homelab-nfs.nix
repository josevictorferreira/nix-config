{ lib, config, pkgs, ... }:
with lib;

let
  cfg = config.homelab.nfs;

  optsList = [
    "vers=${cfg.nfsVersion}"
    "rw"
    "hard"
    "timeo=${toString cfg.timeo}"
    "retrans=${toString cfg.retrans}"
    "rsize=${toString cfg.rsize}"
    "wsize=${toString cfg.wsize}"
    "nfc"
    "nosuid"
    "nodev"
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

    nfsVersion = mkOption { type = types.enum [ "4" "4.1" "4.2" ]; default = "4.1"; };
    rsize = mkOption { type = types.int; default = 1048576; };
    wsize = mkOption { type = types.int; default = 1048576; };
    timeo = mkOption { type = types.int; default = 600; description = "Tenths of a second."; };
    retrans = mkOption { type = types.int; default = 2; };
    resvport = mkOption { type = types.bool; default = false; description = "Some NASes still require reserved ports."; };
    extraOptions = mkOption { type = types.listOf types.str; default = [ ]; description = "Any extra raw mount options."; };
  };

  config = mkIf cfg.enable {
    users.groups.homelab = { };
    users.users.${cfg.username}.extraGroups = [ "homelab" ];

    system.activationScripts.homelab-nfs-init.text = ''
      #!${pkgs.bash}/bin/bash
      set -eu
      mkdir -p "${cfg.mountPoint}"
      chgrp -f homelab "${cfg.mountPoint}" || true
      chmod 775 "${cfg.mountPoint}" || true
    '';

    environment.etc."fstab".text = ''
      ${fstabLine}
    '';

    system.activationScripts.homelab-nfs-automount-reload.text = ''
      #!${pkgs.bash}/bin/bash
      /usr/sbin/automount -cv >/dev/null 2>&1 || true
    '';

    launchd.daemons.homelab-nfs-touch = {
      serviceConfig = {
        Label = "org.nix-darwin.homelab-nfs-touch";
        ProgramArguments = [ "/bin/ls" cfg.mountPoint ];
        RunAtLoad = true;
        StandardOutPath = "/var/log/homelab-nfs-touch.log";
        StandardErrorPath = "/var/log/homelab-nfs-touch.err";
      };
    };
  };
}
