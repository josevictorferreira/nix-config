{ config
, lib
, system
, ...
}:

let
  cfg = config.jvf.hardware.bluetooth;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  options.jvf.hardware.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth support" // {
      description = ''
        Whether to enable Bluetooth hardware support.
        Configures Bluetooth daemon with profile support.
      '';
    };

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

  config = lib.mkIf cfg.enable (
    if (!isDarwin) then
      {
        hardware.bluetooth = {
          enable = true;
          inherit (cfg) powerOnBoot;
          settings.General = {
            Enable = lib.mkDefault (lib.concatStringsSep "," cfg.profiles);
            Experimental = lib.mkDefault cfg.enableExperimental;
          };
        };

        services.blueman.enable = lib.mkDefault true;
      }
    else
      { }
  );
}
