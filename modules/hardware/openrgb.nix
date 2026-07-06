# Aspect: hardware-openrgb
# OpenRGB support: RGB lighting control for PC hardware.
# NixOS-only (no Darwin equivalent).
_:
let
  mkConfig =
    { pkgs
    , ...
    }:
    {
      config = {
        environment.systemPackages = [
          pkgs.openrgb-with-all-plugins
        ];

        # Enable the service (installs udev rules + loads i2c module so
        # non-root access works) and target the AMD SMBus for detection.
        services.hardware.openrgb = {
          enable = true;
          package = pkgs.openrgb-with-all-plugins;
          motherboard = "amd";
        };

        # DDR4 RGB RAM sits on the SMBus that ACPI claims; without this the
        # kernel blocks userspace i2c access and OpenRGB can't see the RAM.
        boot.kernelParams = [ "acpi_enforce_resources=lax" ];
      };
    };
in
{
  flake.modules.nixos.hardware-openrgb = mkConfig;
}
