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
          enabled = true;
          command = [
            "${pkgs.bun}/bin/bunx"
            "--bun"
            "shadcn@latest"
            "mcp"
          ];
        };

        context7 = {
          type = "remote";
          enabled = true;
          url = "https://mcp.context7.com/mcp";
          headers = {
            CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
          };
        };

        playwright = {
          type = "local";
          enabled = true;
          command = [
            (lib.getExe pkgs.playwright-mcp)
            "--executable-path"
            browserExecutable
          ];
        };

        chrome-devtools = {
          type = "local";
          enabled = true;
          command = [
            "${pkgs.lib.getExe' pkgs.nodejs "npx"}"
            "-y"
            "chrome-devtools-mcp@latest"
            "--headless=true"
            "--isolated=true"
            "--executablePath=${browserExecutable}"
          ];
        };

        podman-mcp = {
          type = "local";
          enabled = true;
          command = [
            "${pkgs.lib.getExe' pkgs.nodejs "npx"}"
            "-y"
            "podman-mcp-server@latest"
          ];
        };
      }
      // lib.optionalAttrs (!isDarwin) {
        mcp-nixos = {
          type = "local";
          enabled = true;
          command = [
            (lib.getExe pkgs.mcp-nixos)
          ];
        };
      }
    );
    tools = (
      {
        "chrome-devtools*" = false;
        "playwright*" = false;
        "context7*" = false;
        "shadcn*" = false;
        "podman-mcp*" = false;
      }
      // lib.optionalAttrs (!isDarwin) {
        "mcp-nixos*" = false;
      }
    );
  };
}
