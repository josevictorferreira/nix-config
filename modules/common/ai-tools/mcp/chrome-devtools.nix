{ lib, pkgs, config, system, ... }:

let
  cfg = config.jvf.aiTools.mcp."chrome-devtools";
  isDarwin = builtins.match "*-darwin" system != null;
  defaultBrowser = if isDarwin then lib.getExe pkgs.google-chrome else lib.getExe pkgs.chromium;
  npx = lib.getExe' pkgs.nodejs "npx";
in
{
  options.jvf.aiTools.mcp."chrome-devtools" = {
    enable = lib.mkEnableOption "Chrome DevTools MCP server";

    executable = lib.mkOption {
      type = lib.types.path;
      default = defaultBrowser;
      description = lib.mdDoc "Browser executable path used by Chrome DevTools MCP.";
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
    jvf.aiTools.mcp."chrome-devtools"._output = {
      opencode = {
        type = "local";
        enabled = true;
        command = [
          npx
          "-y"
          "chrome-devtools-mcp@latest"
          "--headless=true"
          "--isolated=true"
          "--executablePath=${cfg.executable}"
        ] ++ cfg.args;
        env = cfg.env;
      };
    };
  };
}

