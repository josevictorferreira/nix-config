{
  lib,
  pkgs,
  config,
  inputs,
  system,
  ...
}:

let
  cfg = config.jvf.aiTools.mcp."chrome-devtools";
  isDarwin = builtins.match ".*-darwin" system != null;
  defaultBrowser = if isDarwin then lib.getExe pkgs.google-chrome else lib.getExe pkgs.chromium;
  npx = lib.getExe' pkgs.nodejs "npx";

  mcpDef = inputs.lib.aiTools.mkMcpModule {
    name = "chrome-devtools";
    tags = [ "browser" ];
    config = {
      jvf.programs.opencode.mcps."chrome-devtools" = {
        type = "local";
        enabled = true;
        command = [
          npx
          "-y"
          "chrome-devtools-mcp@latest"
          "--headless=true"
          "--isolated=true"
          "--executablePath=${defaultBrowser}"
        ];
      };

      jvf.programs.claudecode.mcps."chrome-devtools" = {
        type = "stdio";
        command = "npx";
        args = [
          "-y"
          "chrome-devtools-mcp@latest"
          "--headless=true"
          "--isolated=true"
          "--executablePath=${defaultBrowser}"
        ];
      };
    };
  };
in
{
  options.jvf.aiTools.mcp."chrome-devtools" = mcpDef.options;

  config = lib.mkIf cfg.enable mcpDef.config;
}
