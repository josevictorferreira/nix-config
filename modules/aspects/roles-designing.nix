# Aspect: roles-designing
# Bundles design and creative tools (inkscape).
{ ... }:
let
  mkOptions =
    { lib, ... }:
    {
      options.jvf.roles.designing = {
        enable = lib.mkEnableOption "designing tools bundle";

        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for installing packages to.";
        };
      };
    };

  mkConfig =
    { isDarwin }:
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

      config = lib.mkIf cfg.enable {
        users.users."${cfg.username}".packages = [
          pkgs.inkscape-with-extensions
        ];
      };
    };
in
{
  flake.modules.nixos.roles-designing = mkConfig { isDarwin = false; };
  flake.modules.darwin.roles-designing = mkConfig { isDarwin = true; };
}
