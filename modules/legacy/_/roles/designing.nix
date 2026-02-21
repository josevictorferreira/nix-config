{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.jvf.roles.designing;
in
{
  options.jvf.roles.designing = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable designing tools.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
      description = "Username for installing packages to.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users."${cfg.username}".packages = [
      pkgs.inkscape-with-extensions
    ];
  };
}
