{
  lib,
  pkgs,
  system,
  ...
}:
let
  isDarwin = builtins.match ".*-darwin" system != null;
  browserExecutable = if isDarwin then lib.getExe pkgs.google-chrome else lib.getExe pkgs.chromium;
in
{
  config.jvf.programs.opencode.settings = {
    mcp = (
      {
        shadcn = {
          type = "local";
          enabled = false;
          command = [
            "${pkgs.bun}/bin/bunx"
            "--bun"
            "shadcn@latest"
            "mcp"
          ];
        };

        context7 = {
          type = "remote";
          enabled = false;
          url = "https://mcp.context7.com/mcp";
          headers = {
            CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
          };
        };

        playwright = {
          type = "local";
          enabled = false;
          command = [
            (lib.getExe pkgs.playwright-mcp)
            "--executable-path"
            browserExecutable
          ];
        };

        chrome-devtools = {
          type = "local";
          enabled = false;
          command = [
            "${pkgs.lib.getExe' pkgs.nodejs "npx"}"
            "-y"
            "chrome-devtools-mcp@latest"
            "--headless=true"
            "--isolated=true"
            "--executablePath=${browserExecutable}"
          ];
        };
      }
      // lib.optionalAttrs (!isDarwin) {
        mcp-nixos = {
          type = "local";
          enabled = false;
          command = [
            (lib.getExe pkgs.mcp-nixos)
          ];
        };
      }
    );
    tools = (
      {
        chrome-devtools = false;
        playwright = false;
        context7 = false;
        shadcn = false;
        github = false;
      }
      // lib.optionalAttrs (!isDarwin) {
        mcp-nixos = false;
      }
    );
  };
}
