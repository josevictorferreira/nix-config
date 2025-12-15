{
  lib,
  config,
  inputs,
  ...
}:

let
  cfg = config.jvf.aiTools.mcp.context7;
  mcpDef = inputs.lib.aiTools.mkMcpModule {
    name = "context7";
    tags = [ "documentation" ];
    config = {
      jvf.programs.opencode.mcps."context7" = {
        enabled = true;
        type = "local";
        command = [
          "npx"
          "-y"
          "@upstash/context7-mcp"
          "--api-key"
          "{env:CONTEXT7_API_KEY}"
        ];
      };
      jvf.programs.claudecode.mcps."context7" = {
        type = "stdio";
        command = "npx";
        args = [
          "-y"
          "@upstash/context7-mcp"
          "--api-key"
          "{env:CONTEXT7_API_KEY}"
        ];
      };
    };
  };
in
{
  options.jvf.aiTools.mcp.context7 = mcpDef.options;

  config = lib.mkIf cfg.enable mcpDef.config;
}
