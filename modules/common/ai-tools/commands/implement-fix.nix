{ config, lib, ... }:
let
  cfg = config.jvf.aiTools.commands.implement-fix;
  commandOptions = {
    name = "Implement Fix";
    description = "Plan and proceed to implement a bug fix based on a prompt enhanced by a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      $ARGUMENTS
    '';
  };
in
{
  options.jvf.aiTools.commands.implement-fix = {
    enable = (lib.mkEnableOption "Enable the implement-fix command") // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.commands."implement-fix" = commandOptions;
    jvf.programs.claudecode.commands."implement-fix" = commandOptions;
  };
}
