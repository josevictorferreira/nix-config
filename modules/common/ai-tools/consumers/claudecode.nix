{ lib, config, ... }:

let
  aiLib = import ../lib.nix { inherit lib; };
  cfg = config.jvf.aiTools;

  mkPrefixed =
    prefix: entries:
    lib.mapAttrs'
      (name: value: {
        name = "${prefix}/${name}/SKILL.md";
        value = aiLib.toClaudeMarkdownPrompt value;
      })
      entries;

  enabledAgents = lib.filterAttrs (_: v: v.enable or false) cfg.agents;
  enabledCommands = lib.filterAttrs (_: v: v.enable or false) cfg.commands;

in
{
  config = lib.mkIf cfg.enable {
    jvf.aiTools.consumers.claudecode = {
      skills = mkPrefixed "skills" enabledAgents;
      commands = mkPrefixed "commands" enabledCommands;
    };
  };
}

