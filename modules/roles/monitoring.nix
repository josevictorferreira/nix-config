{
  config,
  lib,
  ...
}:

let
  cfg = config.jvf.roles.monitoring;
in
{
  imports = [
    ../programs/btop.nix
  ];

  options.jvf.roles.monitoring.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable administrative tools.";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.btop.enable = true;
  };
}
