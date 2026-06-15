# Aspect: roles-desktop
# Desktop environment system configuration.
# Imports: audio, display, logind, power-management, xdg, flatpak.
# NixOS-only: all of these are NixOS-specific system services.
{ self, ... }:
let
  nixosAspects = self.modules.nixos;

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.desktop = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for desktop configuration.";
        };
      };
    };

  nixosModule =
    { config, ... }:
    let
      cfg = config.jvf.roles.desktop;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with nixosAspects; [
        system-audio
        system-display
        system-logind
        system-power-management
        system-xdg
        system-flatpak
        programs-pomodoro
      ]);

      config = {
        jvf.system.power-management.username = cfg.username;
        jvf.system.xdg.username = cfg.username;
      };
    };

  darwinModule =
    { ... }:
    {
      imports = [ mkOptions ];
    };
in
{
  flake.modules.nixos.roles-desktop = nixosModule;
  flake.modules.darwin.roles-desktop = darwinModule;
}
