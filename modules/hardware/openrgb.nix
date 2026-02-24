# Aspect: hardware-openrgb
# OpenRGB support: RGB lighting control for PC hardware.
# NixOS-only (no Darwin equivalent).
{ ... }:
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
      };
    };
in
{
  flake.modules.nixos.hardware-openrgb = mkConfig;
}
