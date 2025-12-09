{ lib, config, ... }:
{
  options.jvf.aiTools.commands."implement-change" = (lib.mkCommandModule {
    name = "Implement Change";
    description = "Plan and proceed to implement a change based on a prompt enhanced by a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      !`prompt-enhancer change "$ARGUMENTS";`
    '';
  }).options;

  config = lib.mkIf config.jvf.aiTools.enable { };
}
