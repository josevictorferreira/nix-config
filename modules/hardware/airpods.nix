# Aspect: hardware-airpods
# LibrePods: AirPods battery, listening-mode control, and ear detection on Linux.
# NixOS-only. Requires Apple VendorID spoofing (see hardware-bluetooth DeviceID).
_:
let
  mkAirpodsOptions =
    { config, lib, ... }:
    {
      options.jvf.hardware.airpods = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Primary user to add to the librepods group.";
        };
      };
    };

  mkConfig =
    { config, ... }:
    let
      cfg = config.jvf.hardware.airpods;
    in
    {
      imports = [ mkAirpodsOptions ];

      config = {
        # Installs librepods plus a cap_net_admin wrapper gated on the
        # librepods group; the raw L2CAP socket to the AirPods needs it.
        programs.librepods.enable = true;

        users.users.${cfg.username}.extraGroups = [ "librepods" ];
      };
    };
in
{
  flake.modules.nixos.hardware-airpods = mkConfig;
}
