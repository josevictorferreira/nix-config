{ lib
, config
, pkgs
, username
, system
, ...
}:

let
  cfg = config.jvf.system.virtualization;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  options.jvf.system.virtualization = {
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

  config = lib.mkIf cfg.enable (
    if (!isDarwin) then
      {
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
      }
    else
      { }
  );
}
