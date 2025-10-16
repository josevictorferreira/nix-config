{
  config,
  lib,
  ...
}:

let
  cfg = config.jvf.profiles.agenticCoding;
in
{
  imports = [
    ../programs/opencode
  ];

  options.jvf.profiles.agenticCoding.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Whether to enable vibe coding tools.";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.enable = true;
  };
}
