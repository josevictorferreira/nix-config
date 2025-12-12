{ config, lib, ... }:
let
  cfg = config.jvf.aiTools.commands.implement-tests;
  commandOptions = {
    name = "Implement Tests";
    description = "Plan and proceed to implement tests based on a prompt enhanced by a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      $ARGUMENTS
    '';
  };
in
{
  options.jvf.aiTools.commands.implement-tests = {
    enable = (lib.mkEnableOption "Enable the implement-tests command") // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.commands."implement-tests" = commandOptions;
    jvf.programs.claudecode.commands."implement-tests" = commandOptions;
  };
}
