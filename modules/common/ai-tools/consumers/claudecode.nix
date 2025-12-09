{ lib, config, ... }:

let
  aiLib = import ../lib.nix { inherit lib; };
  cfg = config.jvf.aiTools;

  mkMd = lib.mapAttrs' (name: value: {
    name = name;
    value = aiLib.toClaudeMarkdownPrompt value;
  });

  enabledAgents = lib.filterAttrs (_: v: v.enable or false) cfg.agents;
  enabledCommands = lib.filterAttrs (_: v: v.enable or false) cfg.commands;

in
{
  config = lib.mkIf cfg.enable {
    jvf.aiTools.consumers.claudecode = {
      skills = mkMd enabledAgents;
      commands = mkMd enabledCommands;
    };
  };
}
