# Aspect: roles-base
# Fundamental system configuration every host needs.
# Imports: base-programs, base-services, environment, firewall, networking.
{ self, ... }:
let
  nixosAspects = self.modules.nixos;
  darwinAspects = self.modules.darwin;

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.base = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for configuration.";
        };
      };
    };

  nixosModule =
    { config, ... }:
    {
      imports = [
        mkOptions
      ]
      ++ (with nixosAspects; [
        system-base-programs
        system-base-services
        system-environment
        system-firewall
        system-networking
      ]);

      config = {
        jvf.system.networking.hostName = config.jvf.core.host;
      };
    };

  darwinModule =
    { config, ... }:
    {
      imports = [
        mkOptions
      ]
      ++ (with darwinAspects; [
        system-base-programs
        system-environment
        system-networking
      ]);

      config = {
        jvf.system.networking.hostName = config.jvf.core.host;
      };
    };
in
{
  flake.modules.nixos.roles-base = nixosModule;
  flake.modules.darwin.roles-base = darwinModule;
}
