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
    mcpOptions = {
      opencode = {
        type = "remote";
        enabled = true;
        url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };

      claudecode = {
        type = "http";
        url = "https://api.z.ai/api/mcp/web_search_prime/mcp";
        headers = {
          Authorization = "Bearer {env:Z_AI_API_KEY}";
        };
      };

      droid = {
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
