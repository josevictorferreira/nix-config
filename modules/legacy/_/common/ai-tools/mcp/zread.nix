{ lib
, config
, inputs
, ...
}:

let
  cfg = config.jvf.aiTools.mcp."zread";
  mcpDef = inputs.lib.aiTools.mkMcpModule {
    name = "zread";
    tags = [ "explorer" ];
    mcpOptions = {
      opencode = {
        type = "remote";
        enabled = true;
        url = "https://api.z.ai/api/mcp/zread/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };

      claudecode = {
        type = "http";
        url = "https://api.z.ai/api/mcp/zread/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };

      droid = {
        type = "http";
        url = "https://api.z.ai/api/mcp/zread/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };
    };
  };
in
{
  options.jvf.aiTools.mcp."zread" = mcpDef.options;

  config = lib.mkIf cfg.enable mcpDef.config;
}
