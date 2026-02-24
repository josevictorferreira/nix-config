# Aspect: roles-communication
# Bundles communication tools (discord, slack, telegram, weechat).
# Imports weechat program aspect with matrix support.
{ self, ... }:
let
  nixosAspects = self.modules.nixos;
  darwinAspects = self.modules.darwin;

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.communication = {
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
      cfg = config.jvf.roles.communication;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with nixosAspects; [
        programs-weechat
      ]);

      config = {
        jvf.programs.weechat.matrix.enable = true;

        users.users."${cfg.username}".packages = [
          pkgs.discord
          pkgs.brave
        ];
      };
    };

  darwinModule =
    { config
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.communication;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with darwinAspects; [
        programs-weechat
      ]);

      config = {
        jvf.programs.weechat.matrix.enable = true;

        users.users."${cfg.username}".packages = [
          pkgs.discord
          pkgs.brave
        ];
      };
    };
in
{
  flake.modules.nixos.roles-communication = nixosModule;
  flake.modules.darwin.roles-communication = darwinModule;
}
