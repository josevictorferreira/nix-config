{ lib, pkgs, ... }:
{
  config.jvf.programs.opencode.settings.mcp = {
    github = {
      type = "local";
      command = [
        (lib.getExe pkgs.github-mcp-server)
        "--read-only"
        "stdio"
      ];
      enabled = false;
    };

    shadcn = {
      type = "local";
      command = [
        "${pkgs.bun}/bin/bunx"
        "--bun"
        "shadcn@latest"
        "mcp"
      ];
      enabled = true;
    };

    chrome-devtools = {
      type = "local";
      command = [
        "${pkgs.lib.getExe' pkgs.nodejs "npx"}"
        "-y"
        "chrome-devtools-mcp@latest"
        "--headless=true"
        "--isolated=true"
        "--executablePath=${pkgs.chromium}/bin/chromium"
      ];
      enabled = true;
    };

    context7 = {
      type = "remote";
      url = "https://mcp.context7.com/mcp";
      headers = {
        CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
      };
      enabled = true;
    };

    socket = {
      type = "remote";
      url = "https://mcp.socket.dev/";
      enabled = false;
    };
  };
}
