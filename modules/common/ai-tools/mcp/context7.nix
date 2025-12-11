{ lib, config, ... }:

let
  cfg = config.jvf.aiTools.mcp.context7;
in
{
  options.jvf.aiTools.mcp.context7 = {
    enable = (lib.mkEnableOption "Context7 MCP server") // { default = true; };
  };

  config = lib.mkIf cfg.enable {
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
      command = "npx";
      args = [
        "-y"
        "@upstash/context7-mcp"
        "--api-key"
        "{env:CONTEXT7_API_KEY}"
      ];
    };
  };
}
