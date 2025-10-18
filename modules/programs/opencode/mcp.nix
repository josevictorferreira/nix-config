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

    socket = {
      type = "remote";
      url = "https://mcp.socket.dev/";
      enabled = false;
    };
  };
}
