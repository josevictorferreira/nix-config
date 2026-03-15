{ ... }:
{
  name = "do";
  description = "Enhance and run a prompt using a specified (or defaulted) model.";
  agent = "build";
  prompt = ''
    !`prompt-enhancer bare "$ARGUMENTS";`
  '';
}
