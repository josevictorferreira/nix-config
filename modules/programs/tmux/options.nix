# Tmux and tmuxp options definitions
{
  config,
  lib,
  pkgs,
  ...
}:
let
  defaultPlugins = [
    pkgs.tmuxPlugins.yank
    pkgs.tmuxPlugins.onedark-theme
  ];
in
{
  options.jvf.programs.tmux = {
    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username for which to install the configuration";
    };
    package = lib.mkPackageOption pkgs "tmux" { };
    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = defaultPlugins;
      description = "List of tmux plugins to install.";
    };
  };

  options.jvf.programs.tmuxp = {
    enable = lib.mkEnableOption "tmuxp, a tmux session manager";
    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username for which to install the configuration";
    };
    package = lib.mkPackageOption pkgs "tmuxp" { };
  };
}
