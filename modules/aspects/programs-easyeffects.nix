{ lib, ... }:
let
  mkOptions =
    { ... }:
    {
      enable = lib.mkEnableOption "easyeffects, an audio effects pipeline for PipeWire";
      username = lib.mkOption {
        type = lib.types.str;
        default = "josevictor";
        description = "Username for which to install the configuration";
      };
    };

  mkConfig =
    { isDarwin }:
    { pkgs, config, ... }:
    let
      cfg = config.jvf.programs.easyeffects;
    in
    {
      options.jvf.programs.easyeffects = mkOptions { };

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
  flake.modules.nixos.programs-easyeffects = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-easyeffects = mkConfig { isDarwin = true; };
}
