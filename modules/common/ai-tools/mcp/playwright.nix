{ lib, pkgs, config, system, ... }:

let
  cfg = config.jvf.aiTools.mcp.playwright;
  isDarwin = builtins.match "*-darwin" system != null;
  defaultBrowser = if isDarwin then lib.getExe pkgs.google-chrome else lib.getExe pkgs.chromium;
in
{
  options.jvf.aiTools.mcp.playwright = {
    enable = lib.mkEnableOption "Playwright MCP server";

    package = lib.mkPackageOption pkgs "playwright-mcp" { };

    executable = lib.mkOption {
      type = lib.types.path;
      default = defaultBrowser;
      description = lib.mdDoc "Browser executable used by Playwright MCP.";
    };

    args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = lib.mdDoc "Additional arguments passed to the MCP executable.";
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
    jvf.aiTools.mcp.playwright._output = {
      opencode = {
        type = "local";
        enabled = true;
        command = [
          (lib.getExe cfg.package)
          "--executable-path"
          cfg.executable
        ] ++ cfg.args;
        env = cfg.env;
      };
    };
  };
}

