{ lib, config, ... }:
{
  options.jvf.aiTools.commands."implement-refactoring" = (lib.mkCommandModule {
    name = "Implement Refactoring";
    description = "Plan and proceed to implement a change based on a prompt enhanced by a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      !`prompt-enhancer refactoring "$ARGUMENTS";`
    '';
  }).options;

  config = lib.mkIf config.jvf.aiTools.enable { };
}
