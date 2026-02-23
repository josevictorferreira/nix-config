# Aspect: roles-designing
# Bundles design and creative tools (inkscape).
{ self, ... }:
let
  nixosAspects = self.modules.nixos;
  darwinAspects = self.modules.darwin;

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.designing = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };
      };
    };

  nixosModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.roles.designing;
    in
    {
      imports = [ mkOptions ];

      config = {
        users.users."${cfg.username}".packages = [
          pkgs.inkscape-with-extensions
        ];
      };
    };

  darwinModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.roles.designing;
    in
    {
      imports = [ mkOptions ];

      config = {
        users.users."${cfg.username}".packages = [
          pkgs.inkscape-with-extensions
        ];
      };
    };
in
{
  flake.modules.nixos.roles-designing = nixosModule;
  flake.modules.darwin.roles-designing = darwinModule;
}
