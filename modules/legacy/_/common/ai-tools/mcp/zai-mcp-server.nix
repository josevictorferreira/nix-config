{ lib
, config
, inputs
, pkgs
, ...
}:

let
  cfg = config.jvf.aiTools.mcp."zai-mcp-server";
  mcpDef = inputs.lib.aiTools.mkMcpModule {
    name = "zai-mcp-server";
    tags = [ "explorer" ];
    mcpOptions = {
      opencode = {
        type = "local";
        enabled = true;
        command = [
          "${lib.getExe' pkgs.nodejs "npx"}"
          "-y"
          "@z_ai/mcp-server"
        ];
        environment = {
          "Z_AI_API_KEY" = "{env:Z_AI_API_KEY}";
          "Z_AI_MODE" = "ZAI";
        };
      };

      claudecode = {
        type = "stdio";
        command = "${lib.getExe' pkgs.nodejs "npx"}";
        args = [
          "-y"
          "@z_ai/mcp-server"
        ];
        env = {
          "Z_AI_API_KEY" = "{env:Z_AI_API_KEY}";
          "Z_AI_MODE" = "ZAI";
        };
      };

      droid = {
        type = "stdio";
        command = "${lib.getExe' pkgs.nodejs "npx"}";
        args = [
          "-y"
          "@z_ai/mcp-server"
        ];
        env = {
          "Z_AI_API_KEY" = "{env:Z_AI_API_KEY}";
          "Z_AI_MODE" = "ZAI";
        };
      };
    };
  };
in
{
  options.jvf.aiTools.mcp."zai-mcp-server" = mcpDef.options;

  config = lib.mkIf cfg.enable mcpDef.config;
}
