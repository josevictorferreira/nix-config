{ lib }:

{
  implement-refactoring = lib.mkCommand {

    name = "Implement Refactoring";
    description = "Plan and proceed to implement a change based on a prompt enhanced by a specified (or defaulted) model.";
    tools = [ ];
    prompt = ''
      !`prompt-enhancer refactoring "$ARGUMENTS";`
    '';
  };
}
