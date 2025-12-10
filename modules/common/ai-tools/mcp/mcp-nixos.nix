{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.jvf.aiTools.mcp."mcp-nixos";
in
{
  options.jvf.aiTools.mcp."mcp-nixos" = {
    enable = lib.mkEnableOption "NixOS MCP server (Linux only)";
  };

  config = lib.mkIf cfg.enable {
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
}
