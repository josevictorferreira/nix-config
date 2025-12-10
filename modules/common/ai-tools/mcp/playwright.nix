{
  lib,
  pkgs,
  config,
  system,
  ...
}:

let
  cfg = config.jvf.aiTools.mcp.playwright;
  isDarwin = builtins.match ".*-darwin" system != null;
  defaultBrowser = if isDarwin then lib.getExe pkgs.google-chrome else lib.getExe pkgs.chromium;
in
{
  options.jvf.aiTools.mcp.playwright = {
    enable = lib.mkEnableOption "Playwright MCP server";
  };

  config = lib.mkIf cfg.enable {
    jvf.programs.opencode.mcps."playwright" = {
      type = "local";
      enabled = true;
      command = [
        (lib.getExe pkgs.playwright-mcp)
        "--executable-path"
        defaultBrowser
      ];
    };
    jvf.programs.claudecode.mcps."playwright" = {
      type = "stdio";
      command = lib.getExe pkgs.playwright-mcp;
      args = [
        "--executable-path"
        defaultBrowser
      ];
    };
  };
}
