# Aspect: roles-desktop
# Desktop environment system configuration.
# Enables: audio, display, logind, power-management, xdg, flatpak.
# NixOS-only: all of these are NixOS-specific system services.
{ ... }:
let
  mkDesktopOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.desktop = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable desktop system configuration.";
        };

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for desktop configuration.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.jvf.roles.desktop;
    in
    {
      imports = [ mkDesktopOptions ];

      config = lib.mkIf cfg.enable (
        if !isDarwin then
          {
            jvf.system.audio.enable = true;
            jvf.system.display.enable = true;
            jvf.system.logind.enable = true;
            jvf.system.power-management.enable = true;
            jvf.system.power-management.username = cfg.username;
            jvf.system.xdg.enable = true;
            jvf.system.xdg.username = cfg.username;
            jvf.system.flatpak.enable = true;
          }
        else
          { }
      );
    };
in
{
  flake.modules.nixos.roles-desktop = mkConfig { isDarwin = false; };
  flake.modules.darwin.roles-desktop = mkConfig { isDarwin = true; };
}
