# Aspect: roles-designing
# Bundles design and creative tools (inkscape).
{ ... }:
let
  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.designing = {
        enable = lib.mkEnableOption "designing tools bundle";

        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };
      };
    };

  designingModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.designing;
    in
    {
      imports = [ mkOptions ];

      config = lib.mkIf cfg.enable {
        users.users."${cfg.username}".packages = [
          pkgs.inkscape-with-extensions
        ];
      };
    };
in
{
  flake.modules.nixos.roles-designing = designingModule;
  flake.modules.darwin.roles-designing = designingModule;
}
