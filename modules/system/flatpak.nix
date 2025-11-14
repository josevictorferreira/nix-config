{ config, lib, pkgs, ... }:

let
  cfg = config.jvf.system.flatpak;
in
{
  options.jvf.system.flatpak = {
    enable = lib.mkEnableOption "flatpak support" // {
      description = ''
        Whether to enable Flatpak support and setup common repositories.
        Includes Flathub repository configuration.
      '';
    };

    enableFlathub = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically add Flathub repository during system activation.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    services.rpcbind.enable = true;

    systemd.services.flatpak-repo = lib.mkIf cfg.enableFlathub {
      path = [ pkgs.flatpak ];
      script = ''
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };
}
