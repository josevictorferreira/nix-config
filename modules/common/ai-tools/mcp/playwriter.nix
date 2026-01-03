{ lib
, pkgs
, config
, inputs
, ...
}:

let
  cfg = config.jvf.aiTools.mcp.playwriter;

  mcpDef = inputs.lib.aiTools.mkMcpModule {
    name = "playwriter";
    tags = [ ];
    config = {
      jvf.programs.opencode.mcps."playwriter" = {
        type = "local";
        enabled = true;
        command = [
          (lib.getExe' pkgs.nodejs "npx")
          "playwriter@latest"
        ];
      };
      jvf.programs.claudecode.mcps."playwriter" = {
        type = "stdio";
        command = (lib.getExe' pkgs.nodejs "npx");
        args = [
          "playwriter@latest"
        ];
      };
    };
  };
in
{
  options.jvf.aiTools.mcp.playwriter = mcpDef.options;

  config = lib.mkIf cfg.enable mcpDef.config;
}
