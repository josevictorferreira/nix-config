# Aspect: roles-designing
# Bundles design and creative tools (inkscape, blender, orca-slicer).
_:
let

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
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.designing;
    in
    {
      imports = [ mkOptions ];

      config = {
        users.users."${cfg.username}".packages = [
          pkgs.inkscape-with-extensions
          pkgs.blender
          pkgs.freecad
          pkgs.orca-slicer
        ];
      };
    };

  darwinModule =
    { config
    , pkgs
    , ...
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
