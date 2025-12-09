{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.aiTools.mcp.shadcn;
in
{
  options.jvf.aiTools.mcp.shadcn = {
    enable = lib.mkEnableOption "shadcn MCP server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.bun;
      description = lib.mdDoc "Package providing bun (for bunx).";
    };

    args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "--bun" "shadcn@latest" "mcp" ];
      description = lib.mdDoc "Arguments passed to bunx for shadcn MCP.";
    };

    env = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = lib.mdDoc "Environment variables for the MCP server.";
    };

    _output = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      readOnly = true;
      description = lib.mdDoc "Computed consumer output.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.aiTools.mcp.shadcn._output = {
      opencode = {
        type = "local";
        enabled = true;
        command = [
          "${cfg.package}/bin/bunx"
        ] ++ cfg.args;
        env = cfg.env;
      };
    };
  };
}
