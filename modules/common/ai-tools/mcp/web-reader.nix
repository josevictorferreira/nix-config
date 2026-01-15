{ lib
, config
, inputs
, ...
}:

let
  cfg = config.jvf.aiTools.mcp."web-reader";
  mcpDef = inputs.lib.aiTools.mkMcpModule {
    name = "web-reader";
    tags = [ "explorer" ];
    config = {
      jvf.programs.opencode.mcps."web-reader" = {
        type = "remote";
        enabled = true;
        url = "https://api.z.ai/api/mcp/web_reader/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };

      jvf.programs.claudecode.mcps."web-reader" = {
        type = "http";
        url = "https://api.z.ai/api/mcp/web_reader/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };

      jvf.programs.droid.mcps."web-reader" = {
        type = "http";
        url = "https://api.z.ai/api/mcp/web_reader/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };
    };
  };
in
{
  options.jvf.aiTools.mcp."web-reader" = mcpDef.options;

  config = lib.mkIf cfg.enable mcpDef.config;
}
