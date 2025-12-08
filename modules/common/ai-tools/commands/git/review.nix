{ lib }:

{
  review = lib.mkCommand {
    name = "Review";
    description = "Analyze staged git changes and provide thorough code review";
    tools = [ ];
    prompt = ''
      Analyze the staged git changes and provide a thorough
      code review with suggestions for improvement, focusing on
      code quality, security, and maintainability.
    '';
  };
}
