{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.jvf.roles.gaming;
in
{
  imports = [
    ../programs/steam.nix
  ];

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

  config = lib.mkIf cfg.enable {
    jvf.programs.steam.enable = true;

    users.users."${cfg.username}".packages = [
      pkgs.lutris
      pkgs.protonup-qt

      pkgs.wine64
      pkgs.winetricks
      pkgs.wine-wayland
    ];
  };
}
