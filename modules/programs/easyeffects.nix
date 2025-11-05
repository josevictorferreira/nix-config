{
  lib,
  pkgs,
  config,
  username,
  ...
}:
let
  cfg = config.jvf.programs.easyeffects;
in
{
  options.jvf.programs.easyeffects = {
    enable = lib.mkEnableOption "easyeffects, an audio effects pipeline for PipeWire";
    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for which to install the configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.easyeffects
    ];

    jvf.repositories.users.${cfg.username}.clonedDirs = {
      ".config/easyeffects" = "git@github.com:josevictorferreira/.easyeffects.git";
    };
  };
}
