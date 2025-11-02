{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.jvf.roles.designing;
in
{
  options.jvf.roles.designing.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable designing tools.";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.inkscape-with-extensions
    ];
  };
}
