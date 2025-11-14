{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.jvf.roles.media;
in
{
  imports = [
    ../programs/easyeffects.nix
    ../programs/steam.nix
  ];

  options.jvf.roles.media = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable media tools.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.easyeffects.enable = true;
    jvf.programs.steam.enable = true;

    users.users."${cfg.username}".packages = [
      pkgs.inkscape-with-extensions
      pkgs.vlc
      pkgs.spotifywm
      pkgs.ffmpeg
      # Gaming
      pkgs.lutris
      pkgs.protonup-qt
      pkgs.wine64
      pkgs.winetricks
      pkgs.wine-wayland
    ];
  };
}
