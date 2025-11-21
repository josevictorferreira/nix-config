{
  config,
  lib,
  system,
  ...
}:

let
  cfg = config.jvf.system.audio;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  options.jvf.system.audio = {
    enable = lib.mkEnableOption "system audio (pipewire) configuration" // {
      description = ''
        Whether to enable system-wide audio configuration using PipeWire.
        Configures:
        - PipeWire daemon
        - ALSA compatibility
        - PulseAudio compatibility
        - WirePlumber session manager
        - 32-bit ALSA support for Wine/Steam
      '';
    };

    alsa32BitSupport = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable 32-bit ALSA support (required for some games/Wine).";
    };

    wireplumberEnable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable WirePlumber session manager for PipeWire.";
    };
  };

  config = lib.mkIf cfg.enable (
    if (!isDarwin) then
      {
        # Disable PulseAudio when using PipeWire
        services.pulseaudio.enable = false;

        # Enable PipeWire with ALSA and PulseAudio compatibility
        services.pipewire = {
          enable = true;
          alsa = {
            enable = true;
            support32Bit = cfg.alsa32BitSupport;
          };
          pulse = {
            enable = true;
          };
          wireplumber = {
            enable = cfg.wireplumberEnable;
          };
        };

        # Enable libinput for input devices (required for audio input)
        services.libinput.enable = true;
      }
    else
      { }
  );
}
