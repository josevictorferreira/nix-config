# Aspect: system-audio
# Defines jvf.system.audio options and platform-specific audio config.
# NixOS: PipeWire with ALSA, PulseAudio compat, WirePlumber.
# Darwin: empty config (audio managed by macOS).
{ ... }:
let
  mkAudioOptions =
    { lib, ... }:
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
    };

  mkConfig =
    { isDarwin }:
    { config, lib, ... }:
    let
      cfg = config.jvf.system.audio;
    in
    {
      imports = [ mkAudioOptions ];

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

            # Enable libinput for input devices
            services.libinput.enable = true;
          }
        else
          { }
      );
    };
in
{
  flake.modules.nixos.system-audio = mkConfig { isDarwin = false; };
  flake.modules.darwin.system-audio = mkConfig { isDarwin = true; };
}
