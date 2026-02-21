{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.jvf.roles.communication;
in
{
  imports = [
    ../programs/weechat
  ];

  options.jvf.roles.communication = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable communication tools.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.weechat = {
      enable = true;
      matrix.enable = true;
    };

    users.users."${cfg.username}".packages = [
      pkgs.discord
      pkgs.brave # Moved from system packages
    ];
  };
}
