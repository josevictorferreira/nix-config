# Default Gemini CLI settings
# Pure data export - no module boilerplate
{ mcps }:
{
  general.previewFeatures = true;
  general.vimMode = true;
  general.preferredEditor = "nvim";
  general.checkpointing.enabled = true;
  general.enablePromptCompletion = true;
  mcp = mcps;
  ui.theme = "Dracula";
  context.fileName = [
    "CLAUDE.md"
    "AGENTS.md"
    "GEMINI.md"
    "CONTEXT.md"
  ];
  tools.autoAccept = true;
  tools.enableHooks = true;
  tools.shell.showCOlor = true;
  tools.shell.pager = "bcat";
  tools.mcp.allowed = builtins.attrNames mcps;
  security.enablePermanentToolApproval = true;
  privacy.usageStatisticsEnabled = true;
  experimental.enableAgents = true;
  experimental.jitContext = true;
  experimental.skills = true;
  experimental.introspectionAgentSettings.enabled = true;
  telemetry.enabled = false;
}
