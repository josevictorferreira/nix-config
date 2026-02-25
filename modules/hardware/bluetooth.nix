# Aspect: hardware-bluetooth
# Defines jvf.hardware.bluetooth options and NixOS Bluetooth config.
# NixOS-only: hardware.bluetooth + blueman service.
_:
let
  mkBluetoothOptions =
    { lib, ... }:
    {
      options.jvf.hardware.bluetooth = {
        powerOnBoot = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to automatically power on Bluetooth devices at boot.
          '';
        };

        enableExperimental = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to enable experimental Bluetooth features.
            This enables advanced profiles and features.
          '';
        };

        profiles = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "Source"
            "Sink"
            "Media"
            "Socket"
          ];
          description = ''
            Bluetooth profiles to enable.
            Common profiles include Source (input), Sink (output), Media, and Socket.
          '';
          example = [
            "Source"
            "Sink"
            "Media"
            "MIDI"
          ];
        };
      };
    };
in
{
  flake.modules.nixos.hardware-bluetooth =
    { config, lib, ... }:
    let
      cfg = config.jvf.hardware.bluetooth;
    in
    {
      imports = [ mkBluetoothOptions ];

      config = {
        hardware.bluetooth = {
          enable = true;
          inherit (cfg) powerOnBoot;
          settings.General = {
            Enable = lib.mkDefault (lib.concatStringsSep "," cfg.profiles);
            Experimental = lib.mkDefault cfg.enableExperimental;
          };
        };

        services.blueman.enable = lib.mkDefault true;
      };
    };
}
