{ lib, ... }:
{
  options.jvf.aiTools.commands."implement-fix" = (lib.mkCommandModule {
    name = "Implement Fix";
    description = "Plan and proceed to implement a bug fix based on a prompt enhanced by a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      !`prompt-enhancer bugfix "$ARGUMENTS";`
    '';
  }).options;
}
