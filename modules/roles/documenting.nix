{ config
, lib
, pkgs
, username
, ...
}:

let
  cfg = config.jvf.roles.documenting;
in
{
  options.jvf.roles.documenting = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable documenting viewing and editing tools.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users."${cfg.username}".packages = [
      pkgs.font-manager
      pkgs.obsidian
      pkgs.koreader
      pkgs.libreoffice
    ];
  };
}
