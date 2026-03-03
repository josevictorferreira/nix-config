# Aspect: roles-documenting
# Bundles document viewing and editing tools (obsidian, zathura, etc).
_:
let

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.documenting = {
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
      cfg = config.jvf.roles.documenting;
    in
    {
      imports = [ mkOptions ];

      config = {
        users.users."${cfg.username}".packages = [
          pkgs.font-manager
          pkgs.obsidian
          pkgs.koreader
          pkgs.zathura
        ];
      };
    };

  darwinModule =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.documenting;
    in
    {
      imports = [ mkOptions ];

      config = {
        users.users."${cfg.username}".packages = [
          pkgs.font-manager
          pkgs.obsidian
          pkgs.koreader
          pkgs.zathura
        ];
      };
    };
in
{
  flake.modules.nixos.roles-documenting = nixosModule;
  flake.modules.darwin.roles-documenting = darwinModule;
}
