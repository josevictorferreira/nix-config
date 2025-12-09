{ lib, ... }:
{
  options.jvf.aiTools.commands."implement-tests" = (lib.mkCommandModule {
    name = "Implement Tests";
    description = "Plan and proceed to implement tests based on a prompt enhanced by a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      !`prompt-enhancer tests "$ARGUMENTS";`
    '';
  }).options;
}
