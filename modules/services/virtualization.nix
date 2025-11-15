{
  lib,
  config,
  pkgs,
  username,
  ...
}:

let
  cfg = config.jvf.services.virtualization;
in
{
  options.jvf.services.virtualization = {
    enable = lib.mkEnableOption "virtualization support (libvirtd and podman)" // {
      description = ''
        Whether to enable virtualization services.
        Configures:
        - libvirtd for KVM/QEMU virtualization
        - Podman with Docker compatibility
      '';
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "The username to use for virtualization services.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    users.users."${cfg.username}".packages = [
      pkgs.podman-compose
      pkgs.podman
    ];
  };
}
