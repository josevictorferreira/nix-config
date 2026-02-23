# Aspect: roles-gaming
# Gaming tools and platforms.
# All platforms: lutris, wine64, winetricks, wine-wayland, vinegar.
# NixOS-only: steam program.
{ self, ... }:
let
  nixosAspects = self.modules.nixos;

  mkOptions =
    { config, lib, ... }:
    {
      options.jvf.roles.gaming = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for installing packages to.";
        };
      };
    };

  nixosModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.gaming;
    in
    {
      imports = [
        mkOptions
      ]
      ++ (with nixosAspects; [
        programs-steam
      ]);

      config = {
        users.users."${cfg.username}".packages = [
          pkgs.lutris
          pkgs.wine64
          pkgs.winetricks
          pkgs.wine-wayland
          pkgs.vinegar
        ];
      };
    };

  darwinModule =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.roles.gaming;
    in
    {
      imports = [ mkOptions ];

      config = {
        users.users."${cfg.username}".packages = [
          pkgs.lutris
          pkgs.wine64
          pkgs.winetricks
          pkgs.wine-wayland
          pkgs.vinegar
        ];
      };
    };
in
{
  flake.modules.nixos.roles-gaming = nixosModule;
  flake.modules.darwin.roles-gaming = darwinModule;
}
