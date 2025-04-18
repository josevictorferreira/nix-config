{ pkgs, lib, config, configRoot, ... }:

with lib;
let
  cfg = config.modules.kitty;
in
{
  options.modules.weechat = {
    enable = mkEnableOption "kitty";
  };
  config = mkIf cfg.enable {
    home = {
      packages = [
        pkgs.kitty
        pkgs.kitty-img
        pkgs.kitty-themes
      ];
      file = {
        ".config/kitty" = {
          source = "${configRoot}/config/kitty";
          recursive = true;
          executable = false;
        };
      };
    };
  };
}
