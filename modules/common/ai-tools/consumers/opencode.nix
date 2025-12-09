{ lib, config, ... }:

let
  aiLib = import ../lib.nix { inherit lib; };
  cfg = config.jvf.aiTools;

  mkMd = lib.mapAttrs' (name: value: {
    name = name;
    value = aiLib.toOpencodeMarkdownPrompt value;
  });

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
      agents = mkMd enabledAgents;
      commands = mkMd enabledCommands;
      mcp = lib.mapAttrs (_: toMcp) enabledMcp;
      toolSettings = toolDisableSettings;
    };
  };
}
