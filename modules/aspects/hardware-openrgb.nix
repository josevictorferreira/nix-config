# Aspect: hardware-openrgb
# OpenRGB support: RGB lighting control for PC hardware.
# NixOS-only (no Darwin equivalent).
{ ... }:
let
  mkConfig =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.hardware.openrgb;
    in
    {
      options.jvf.hardware.openrgb = {
        enable = lib.mkEnableOption "OpenRGB support" // {
          description = ''
            Whether to enable OpenRGB RGB lighting control.
            Installs openrgb-with-all-plugins for hardware RGB management.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          pkgs.openrgb-with-all-plugins
        ];
      };
    };
in
{
  flake.modules.nixos.hardware-openrgb = mkConfig;
}
