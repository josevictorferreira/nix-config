{ config, lib, ... }:
let
  cfg = config.jvf.aiTools.commands.implement-change;
  commandOptions = {
    name = "Implement Change";
    description = "Plan and proceed to implement a change based on a prompt enhanced by a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      $ARGUMENTS
    '';
  };
in
{
  options.jvf.aiTools.commands.implement-change = {
    enable = lib.mkEnableOption "Enable the implement-change command";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.commands."implement-change" = commandOptions;
    jvf.programs.claudecode.commands."implement-change" = commandOptions;
  };
}
