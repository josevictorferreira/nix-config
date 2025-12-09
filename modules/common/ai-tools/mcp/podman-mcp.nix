{ lib, pkgs, config, ... }:

let
  cfg = config.jvf.aiTools.mcp."podman-mcp";
  npx = lib.getExe' pkgs.nodejs "npx";
in
{
  options.jvf.aiTools.mcp."podman-mcp" = {
    enable = lib.mkEnableOption "Podman MCP server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.nodejs;
      description = lib.mdDoc "Package providing npx to run podman MCP.";
    };

    args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "-y" "podman-mcp-server@latest" ];
      description = lib.mdDoc "Arguments passed to npx for podman MCP.";
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
    jvf.aiTools.mcp."podman-mcp"._output = {
      opencode = {
        type = "local";
        enabled = true;
        command = [
          (lib.getExe' cfg.package "npx")
        ] ++ cfg.args;
        env = cfg.env;
      };
    };
  };
}
