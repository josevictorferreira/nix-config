{ config, lib, ... }:
let
  cfg = config.jvf.aiTools.commands.implement-feature;
  commandOptions = {
    name = "Implement Feature";
    description = "Plan and proceed to implement a new feature based on a prompt enhanced by a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      $ARGUMENTS
    '';
  };
in
{
  options.jvf.aiTools.commands.implement-feature = {
    enable = lib.mkEnableOption "Enable the implement-feature command";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.commands."implement-feature" = commandOptions;
    jvf.programs.claudecode.commands."implement-feature" = commandOptions;
  };
}
