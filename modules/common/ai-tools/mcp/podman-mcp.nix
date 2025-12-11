{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.jvf.aiTools.mcp."podman-mcp";
in
{
  options.jvf.aiTools.mcp."podman-mcp" = {
    enable = (lib.mkEnableOption "Podman MCP server") // { default = true; };
  };

  config = lib.mkIf cfg.enable {
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
}
