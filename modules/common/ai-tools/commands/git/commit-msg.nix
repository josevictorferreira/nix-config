{ config, lib, ... }:
let
  cfg = config.jvf.aiTools.commands."commit-msg";
  commandOptions = {
    name = "Commit Message";
    description = "Generate conventional commit message based on staged changes";
    tools = [ ];
    prompt = ''
      Generate a conventional commit message based on the
      staged changes, following the project's commit standards.
    '';
  };
in
{
  options.jvf.aiTools.commands."commit-msg" = {
    enable = (lib.mkEnableOption "Enable the commit-msg command") // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.commands."commit-msg" = commandOptions;
    jvf.programs.claudecode.commands."commit-msg" = commandOptions;
  };
}
