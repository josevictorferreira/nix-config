{ lib }:

{
  implement-feature = lib.mkCommand {

    name = "Implement Feature";
    description = "Plan and proceed to implement a new feature based on a prompt enhanced by a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      !`prompt-enhancer feature "$ARGUMENTS";`
    '';
  };
}
