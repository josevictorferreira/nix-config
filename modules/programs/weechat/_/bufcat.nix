# _/bufcat.nix - Bufcat buflist categorization script for Weechat
{ config, lib, ... }:

let
  cfg = config.jvf.programs.weechat;
in
{
  config = lib.mkIf cfg.bufcat.enable {
    # Load bufcat and optionally set config path
    jvf.programs.weechat.extraInitCommands =
      [ "/python load bufcat.py" ]
      ++ lib.optional (cfg.bufcat.configPath != null)
        "/set plugins.var.python.bufcat.config_path \"${cfg.bufcat.configPath}\"";
  };
}
