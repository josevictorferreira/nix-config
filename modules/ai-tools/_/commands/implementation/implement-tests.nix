{ ... }:
{
  name = "implement-tests";
  description = "Plan and proceed to implement tests based on a prompt enhanced by a specified (or defaulted) model.";
  agent = "build";
  prompt = ''
    !`prompt-enhancer tests "$ARGUMENTS";`
  '';
}
