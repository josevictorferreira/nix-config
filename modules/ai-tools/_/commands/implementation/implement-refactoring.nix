{ ... }:
{
  name = "implement-refactoring";
  description = "Plan and proceed to implement a change based on a prompt enhanced by a specified (or defaulted) model.";
  agent = "build";
  prompt = ''
    !`prompt-enhancer refactoring "$ARGUMENTS";`
  '';
}
