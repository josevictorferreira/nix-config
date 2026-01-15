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
    config = {
      jvf.programs.opencode.mcps."zread" = {
        type = "remote";
        enabled = true;
        url = "https://api.z.ai/api/mcp/zread/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };

      jvf.programs.claudecode.mcps."zread" = {
        type = "http";
        url = "https://api.z.ai/api/mcp/zread/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };

      jvf.programs.droid.mcps."zread" = {
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
