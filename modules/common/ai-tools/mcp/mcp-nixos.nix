{ lib
, pkgs
, config
, inputs
, ...
}:

let
  cfg = config.jvf.aiTools.mcp."mcp-nixos";
  mcpDef = inputs.lib.aiTools.mkMcpModule {
    name = "mcp-nixos";
    config = {
      jvf.programs.opencode.mcps."mcp-nixos" = {
        type = "local";
        enabled = true;
        command = [ (lib.getExe pkgs.mcp-nixos) ];
      };
      jvf.programs.claudecode.mcps."nixos-mcp" = {
        type = "stdio";
        enabled = true;
        command = lib.getExe pkgs.mcp-nixos;
      };
    };
  };
in
{
  options.jvf.aiTools.mcp."mcp-nixos" = mcpDef.options;

  config = lib.mkIf cfg.enable mcpDef.config;
}
