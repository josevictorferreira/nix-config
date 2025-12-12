{ lib
, pkgs
, config
, inputs
, ...
}:

let
  cfg = config.jvf.aiTools.mcp."podman-mcp";
  mcpDef = inputs.lib.aiTools.mkMcpModule {
    name = "podman-mcp";
    tags = [ "containers" ];
    config = {
      jvf.programs.opencode.mcps."podman-mcp" = {
        type = "local";
        enabled = true;
        command = [
          (lib.getExe' pkgs.nodejs "npx")
          "-y"
          "podman-mcp-server@latest"
        ];
      };
      jvf.programs.claudecode.mcps."podman-mcp" = {
        type = "stdio";
        command = lib.getExe' pkgs.nodejs "npx";
        args = [
          "-y"
          "podman-mcp-server@latest"
        ];
      };
    };
  };
in
{
  options.jvf.aiTools.mcp."podman-mcp" = mcpDef.options;

  config = lib.mkIf cfg.enable mcpDef.config;
}
