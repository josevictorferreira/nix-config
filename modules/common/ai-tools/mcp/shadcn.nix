{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.jvf.aiTools.mcp.shadcn;
in
{
  options.jvf.aiTools.mcp.shadcn = {
    enable = lib.mkEnableOption "shadcn MCP server";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.mcps."shadcn" = {
      type = "local";
      enabled = true;
      command = [
        "${pkgs.bun}/bin/bunx"
        "--bun"
        "shadcn@latest"
        "mcp"
      ];
    };
    jvf.programs.claudecode.mcps."shadcn" = {
      type = "stdio";
      command = "${pkgs.bun}/bin/bunx";
      args = [
        "--bun"
        "shadcn@latest"
        "mcp"
      ];
    };
  };
}
