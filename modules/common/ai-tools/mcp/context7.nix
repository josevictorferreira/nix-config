{ lib, config, ... }:

let
  cfg = config.jvf.aiTools.mcp.context7;
in
{
  options.jvf.aiTools.mcp.context7 = {
    enable = lib.mkEnableOption "Context7 MCP server";

    url = lib.mkOption {
      type = lib.types.str;
      default = "https://mcp.context7.com/mcp";
      description = lib.mdDoc "Remote MCP endpoint URL.";
    };

    headers = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}"; };
      description = lib.mdDoc "HTTP headers sent to the MCP server.";
    };

    _output = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      readOnly = true;
      description = lib.mdDoc "Computed consumer output.";
    };
  };

  config = lib.mkIf cfg.enable {
    jvf.aiTools.mcp.context7._output = {
      opencode = {
        type = "remote";
        enabled = true;
        url = cfg.url;
        headers = cfg.headers;
      };
    };
  };
}
