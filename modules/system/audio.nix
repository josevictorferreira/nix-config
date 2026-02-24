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
    { config, ... }:
    let
      cfg = config.jvf.system.audio;
    in
    {
      imports = [ mkAudioOptions ];

      config = (
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
