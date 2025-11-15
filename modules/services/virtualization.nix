{
  config,
  lib,
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
  };

  config = lib.mkIf cfg.enable {
    virtualization.libvirtd.enable = true;
    virtualization.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
