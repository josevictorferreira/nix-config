{
  config,
  lib,
  ...
}:

let
  cfg = config.jvf.services.virtualisation;
in
{
  options.jvf.services.virtualisation = {
    enable = lib.mkEnableOption "virtualisation support (libvirtd and podman)" // {
      description = ''
        Whether to enable virtualisation services.
        Configures:
        - libvirtd for KVM/QEMU virtualisation
        - Podman with Docker compatibility
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
