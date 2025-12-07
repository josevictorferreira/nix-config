{ lib }:

{
  do = lib.mkCommand {

    name = "Do";
    description = "Enhance and run a prompt using a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      !`prompt-enhancer bare "$ARGUMENTS";`
    '';
  };
}
