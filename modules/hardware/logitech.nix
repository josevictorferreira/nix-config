# Aspect: hardware-logitech
# Logitech wireless hardware support for peripherals (mice, keyboards, etc).
# NixOS-only (no Darwin equivalent).
{ ... }:
let
  mkLogitechOptions =
    { lib, ... }:
    {
      options.jvf.hardware.logitech = {
        enableGraphical = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Whether to enable Logitech graphical tools.
            Set to true if you want to use Logitech's GUI configuration tools.
          '';
        };
      };
    };
in
{
  flake.modules.nixos.hardware-logitech =
    { config, lib, ... }:
    let
      cfg = config.jvf.hardware.logitech;
    in
    {
      imports = [ mkLogitechOptions ];

      config = {
        hardware.logitech.wireless = {
          enable = true;
          enableGraphical = lib.mkDefault cfg.enableGraphical;
        };
      };
    };
}
