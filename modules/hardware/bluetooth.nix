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
            # Keep BR/EDR-only: AirPods audio (A2DP/AVRCP/HFP) is all Classic.
            # "dual" + Experimental makes BlueZ advertise the Ranging Profile it
            # cannot service, and the AirPods reconnect-loop every ~40s.
            ControllerMode = lib.mkDefault "bredr";
            # Spoof Apple's Bluetooth vendor ID (0x004C) so AirPods expose the
            # extended AACP feature set to librepods (see hardware-airpods).
            DeviceID = lib.mkDefault "bluetooth:004C:0000:0000";
          };
        };

        # linux-zen compiles btusb with enable_autosuspend=Y (mainline defaults
        # to N). The RTL8761BU dongle stops answering HCI_Create_Connection
        # (0x0405) once suspended, so connects abort locally with
        # br-connection-aborted-by-local and btusb USB-resets the adapter.
        boot.extraModprobeConfig = "options btusb enable_autosuspend=0";

        services.blueman.enable = lib.mkDefault true;
      };
    };
}
