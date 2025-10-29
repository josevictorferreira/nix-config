{ lib
, pkgs
, config
, ...
}:
let
  cfg = config.jvf.programs.weechat;
in
{
  options.jvf.programs.weechat = {
    enable = lib.mkEnableOption "weechat, an extensible chat client";
    package = lib.mkPackageOption pkgs "weechat" { };
    additionalScripts = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "List of weechat scripts to install in addition to the default set.";
    };
    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to weechat configuration file. If provided, will be copied to /etc/weechat/weechatrc";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.aspell
      pkgs.aspellDicts.en
      pkgs.aspellDicts.pt_BR
      pkgs.weechat
    ];
  };
}
