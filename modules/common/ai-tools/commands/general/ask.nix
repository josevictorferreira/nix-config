{ config, lib, ... }:
let
  cfg = config.jvf.aiTools.commands.ask;
  commandOptions = {
    name = "Ask";
    description = "Answer a question based on a prompt enhanced by a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      $ARGUMENTS
    '';
  };
in
{
  options.jvf.aiTools.commands.ask = {
    enable = (lib.mkEnableOption "Enable the ask command") // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.commands."ask" = commandOptions;
    jvf.programs.claudecode.commands."ask" = commandOptions;
  };
}
