{ lib, pkgs, system }:

let
  isDarwin = builtins.match ".*-darwin" system != null;
in
if isDarwin then { } else {
  "mcp-nixos" = {
    opencode = {
      type = "local";
      enabled = true;
      command = [
        lib.getExe
        pkgs.mcp-nixos
      ];
    };
  };
}
