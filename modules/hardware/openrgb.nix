# Aspect: hardware-openrgb
# OpenRGB support: RGB lighting control for PC hardware.
# NixOS-only (no Darwin equivalent).
_:
let
  mkConfig =
    { pkgs
    , lib
    , config
    , ...
    }:
    let
      cfg = config.services.hardware.openrgb;
      # Profile applied at every boot. Lives in the repo (nix store) because the
      # service runs as root with config dir /var/lib/OpenRGB and cannot see the
      # user's ~/.config/OpenRGB profiles.
      startupProfile = ./lights-off.orp;
    in
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

        # The stock module only runs `--server`; it never applies a profile.
        # Replace ExecStart to load the profile in the same process (after
        # device detection, before the server accepts clients).
        systemd.services.openrgb.serviceConfig.ExecStart = lib.mkForce (
          "${cfg.package}/bin/openrgb --server"
          + " --server-port ${toString cfg.server.port}"
          + " --profile ${startupProfile}"
        );

        # DDR4 RGB RAM sits on the SMBus that ACPI claims; without this the
        # kernel blocks userspace i2c access and OpenRGB can't see the RAM.
        boot.kernelParams = [ "acpi_enforce_resources=lax" ];
      };
    };
in
{
  flake.modules.nixos.hardware-openrgb = mkConfig;
}
