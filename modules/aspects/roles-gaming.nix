# Aspect: roles-gaming
# Gaming tools and platforms.
# All platforms: lutris, wine64, winetricks, wine-wayland, vinegar.
# NixOS-only: steam program.
{ ... }:
let
  mkGamingOptions =
    { lib, ... }:
    {
      options.jvf.roles.gaming = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable gaming tools and platforms.";
        };

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
      cfg = config.jvf.roles.gaming;
    in
    {
      imports = [ mkGamingOptions ];

      config = lib.mkIf cfg.enable (
        {
          users.users."${cfg.username}".packages = [
            pkgs.lutris
            pkgs.wine64
            pkgs.winetricks
            pkgs.wine-wayland
            pkgs.vinegar
          ];
        }
        // (
          if !isDarwin then
            {
              jvf.programs.steam.enable = true;
            }
          else
            { }
        )
      );
    };
in
{
  flake.modules.nixos.roles-gaming = mkConfig { isDarwin = false; };
  flake.modules.darwin.roles-gaming = mkConfig { isDarwin = true; };
}
