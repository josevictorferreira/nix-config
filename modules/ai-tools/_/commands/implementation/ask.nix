{ ... }:
{
  name = "ask";
  description = "Answer a question based on a prompt enhanced by a specified (or defaulted) model.";
  agent = "build";
  prompt = ''
    !`prompt-enhancer change "$ARGUMENTS";`
  '';
}
