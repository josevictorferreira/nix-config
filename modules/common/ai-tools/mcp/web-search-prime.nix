{ lib
, config
, inputs
, ...
}:

let
  cfg = config.jvf.aiTools.mcp."web-search-prime";
  mcpDef = inputs.lib.aiTools.mkMcpModule {
    name = "web-search-prime";
    tags = [ "explorer" ];
    config = {
      jvf.programs.opencode.mcps."web-search-prime" = {
        type = "remote";
        enabled = true;
        url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };

      jvf.programs.claudecode.mcps."web-search-prime" = {
        type = "http";
        url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };

      jvf.programs.droid.mcps."web-search-prime" = {
        type = "http";
        url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };
    };
  };
in
{
  options.jvf.aiTools.mcp."web-search-prime" = mcpDef.options;

  config = lib.mkIf cfg.enable mcpDef.config;
}
