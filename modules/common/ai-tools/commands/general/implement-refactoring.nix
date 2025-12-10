{ config, lib, ... }:
let
  cfg = config.jvf.aiTools.commands.implement-refactory;
  commandOptions = {
    name = "Implement Refactoring";
    description = "Plan and proceed to implement a change based on a prompt enhanced by a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      $ARGUMENTS
    '';
  };
in
{
  options.jvf.aiTools.commands.implement-refactory = {
    enable = lib.mkEnableOption "Enable the implement-refactory command";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.commands."implement-refactory" = commandOptions;
    jvf.programs.claudecode.commands."implement-refactory" = commandOptions;
  };
}
