{ lib, pkgs, system }:

let
  isDarwin = builtins.match ".*-darwin" system != null;
  browserExecutable = if isDarwin then lib.getExe pkgs.google-chrome else lib.getExe pkgs.chromium;
  npx = lib.getExe' pkgs.nodejs "npx";
in
{
  "chrome-devtools" = {
    opencode = {
      type = "local";
      enabled = true;
      command = [
        npx
        "-y"
        "chrome-devtools-mcp@latest"
        "--headless=true"
        "--isolated=true"
        "--executablePath=${browserExecutable}"
      ];
    };
  };
}
