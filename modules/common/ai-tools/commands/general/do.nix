{ config, lib, ... }:
let
  cfg = config.jvf.aiTools.commands.do;
  commandOptions = {
    name = "Do";
    description = "Enhance and run a prompt using a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      $ARGUMENTS
    '';
  };
in
{
  options.jvf.aiTools.commands.do = {
    enable = lib.mkEnableOption "Enable the do command";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.commands."do" = commandOptions;
    jvf.programs.claudecode.commands."do" = commandOptions;
  };
}
