{ lib, pkgs, system }:

let
  npx = lib.getExe pkgs.nodejs "npx";
in
{
  "podman-mcp" = {
    opencode = {
      type = "local";
      enabled = true;
      command = [
        npx
        "-y"
        "podman-mcp-server@latest"
      ];
    };
  };
}
