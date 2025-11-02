{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.jvf.roles.media;
in
{
  imports = [
    ../programs/easyeffects.nix
  ];

  options.jvf.roles.media.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable media tools.";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.easyeffects.enable = true;

    environment.systemPackages = [
      pkgs.inkscape-with-extensions
      pkgs.vlc
      pkgs.spotifywm
      pkgs.ffmpeg
    ];
  };
}
