{
  lib,
  pkgs,
  config,
  username,
  system,
  ...
}:

let
  cfg = config.jvf.roles.gaming;
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  imports = if !isDarwin then [ ../programs/steam.nix ] else [ ];

  options.jvf.roles.gaming = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable gaming tools and platforms.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for installing packages to.";
    };
  };

  config =
    lib.mkIf cfg.enable {
      users.users."${cfg.username}".packages = [
        pkgs.lutris

        pkgs.wine64
        pkgs.winetricks
        pkgs.wine-wayland
      ];
    }
    // (
      if !isDarwin then
        {
          jvf.programs.steam.enable = true;
        }
      else
        { }
    );
}
