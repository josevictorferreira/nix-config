{ lib }:

lib.mkCommand {
  name = "Commit Message";
  description = "Generate conventional commit message based on staged changes";
  tools = [ ];
  prompt = ''
    Generate a conventional commit message based on the
    staged changes, following the project's commit standards.
  '';
}
