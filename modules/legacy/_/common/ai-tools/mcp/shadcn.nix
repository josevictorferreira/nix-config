{ lib
, pkgs
, config
, inputs
, ...
}:

let
  mcpDef = inputs.lib.aiTools.mkMcpModule {
    name = "shadcn";
    tags = [
      "frontend"
    ];
    mcpOptions = {
      opencode = {
        type = "local";
        enabled = true;
        command = [
          "${pkgs.bun}/bin/bunx"
          "--bun"
          "shadcn@latest"
          "mcp"
        ];
      };
      claudecode = {
        type = "stdio";
        command = "${pkgs.bun}/bin/bunx";
        args = [
          "--bun"
          "shadcn@latest"
          "mcp"
        ];
      };
    };
  };
  cfg = config.jvf.aiTools.mcp.shadcn;
in
{
  options.jvf.aiTools.mcp.shadcn = mcpDef.options;

  config = lib.mkIf cfg.enable mcpDef.config;
}
