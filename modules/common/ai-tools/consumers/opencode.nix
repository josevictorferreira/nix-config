{ lib, config, ... }:

let
  aiLib = import ../lib.nix { inherit lib; };
  cfg = config.jvf.aiTools;

  mkPrefixed =
    prefix: entries:
    lib.mapAttrs'
      (name: value: {
        name = "${prefix}/${name}.md";
        value = aiLib.toOpencodeMarkdownPrompt value;
      })
      entries;

  toMcp = mcpCfg: mcpCfg._output.opencode or { };

  allTools = lib.unique (aiLib.extractTools (cfg.agents // cfg.commands));
  toolDisableSettings = aiLib.mkToolDisableSettings allTools;

  enabledAgents = lib.filterAttrs (_: v: v.enable or false) cfg.agents;
  enabledCommands = lib.filterAttrs (_: v: v.enable or false) cfg.commands;
  enabledMcp = lib.filterAttrs (_: v: v.enable or false) cfg.mcp;

in
{
  config = lib.mkIf cfg.enable {
    jvf.aiTools.consumers.opencode = {
      agents = mkPrefixed "agent" enabledAgents;
      commands = mkPrefixed "command" enabledCommands;
      mcp = lib.mapAttrs (_: toMcp) enabledMcp;
      toolSettings = toolDisableSettings;
    };
  };
}

