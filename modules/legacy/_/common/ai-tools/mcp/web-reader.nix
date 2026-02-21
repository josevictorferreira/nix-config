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
    mcpOptions = {
      opencode = {
        type = "remote";
        enabled = true;
        url = "https://api.z.ai/api/mcp/web_reader/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };

      claudecode = {
        type = "http";
        url = "https://api.z.ai/api/mcp/web_reader/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };

      droid = {
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
