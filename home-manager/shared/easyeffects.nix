{ pkgs, lib, configRoot, config, ... }:

with lib;
let
  cfg = config.modules.easyeffects;
in
{
  options.modules.easyeffects = {
    enable = mkEnableOption "easyeffects";
  };
  config = mkIf cfg.enable {
    home = {
      packages = [
        pkgs.easyeffects
      ];
      file = {
        ".config/easyeffects/" = {
          source = "${configRoot}/config/easyeffects/";
          recursive = true;
          executable = false;
        };
      };
    };
  };
}
