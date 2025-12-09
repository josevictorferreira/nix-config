{ lib, ... }:
{
  options.jvf.aiTools.commands.do = (lib.mkCommandModule {
    name = "Do";
    description = "Enhance and run a prompt using a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      !`prompt-enhancer bare "$ARGUMENTS";`
    '';
  }).options;
}
