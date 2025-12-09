{ lib, config, ... }:
{
  options.jvf.aiTools.commands.ask = (lib.mkCommandModule {
    name = "Ask";
    description = "Answer a question based on a prompt enhanced by a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      !`prompt-enhancer question "$ARGUMENTS";`
    '';
  }).options;

  config = lib.mkIf config.jvf.aiTools.enable { };
}
