{ config, lib, ... }:
let
  cfg = config.jvf.aiTools.commands.review;
  commandOptions = {
    name = "Review";
    description = "Analyze staged git changes and provide thorough code review";
    tools = [ ];
    prompt = ''
      Analyze the staged git changes and provide a thorough
      code review with suggestions for improvement, focusing on
      code quality, security, and maintainability.
    '';
  };
in
{
  options.jvf.aiTools.commands.review = {
    enable = (lib.mkEnableOption "Enable the review command") // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.commands."review" = commandOptions;
    jvf.programs.claudecode.commands."review" = commandOptions;
  };
}
