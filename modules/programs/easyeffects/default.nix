{ lib, ... }:
let
  mkOptions =
    { config, ... }:
    {
      enable = lib.mkEnableOption "easyeffects, an audio effects pipeline for PipeWire";
      username = lib.mkOption {
        type = lib.types.str;
        default = config.jvf.core.username;
        description = "Username for which to install the configuration";
      };
    };

  easyeffectsModule =
    { pkgs, config, ... }:
    let
      cfg = config.jvf.programs.easyeffects;
    in
    {
      options.jvf.programs.easyeffects = mkOptions { inherit config; };

      config = lib.mkIf cfg.enable {
        users.users."${cfg.username}".packages = [
          pkgs.easyeffects
        ];

        jvf.repositories.users.${cfg.username}.clonedDirs = {
          ".config/easyeffects" = "git@github.com:josevictorferreira/.easyeffects.git";
        };
      };
    };
in
{
  flake.modules.nixos.programs-easyeffects = easyeffectsModule;
  flake.modules.darwin.programs-easyeffects = easyeffectsModule;
}
