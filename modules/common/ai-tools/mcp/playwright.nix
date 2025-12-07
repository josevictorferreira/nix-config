{ lib, pkgs, system }:

let
  isDarwin = builtins.match ".*-darwin" system != null;
  browserExecutable = if isDarwin then lib.getExe pkgs.google-chrome else lib.getExe pkgs.chromium;
in
{
  playwright = {
    opencode = {
      type = "local";
      enabled = true;
      command = [
        (lib.getExe pkgs.playwright-mcp)
        "--executable-path"
        browserExecutable
      ];
    };
  };
}
