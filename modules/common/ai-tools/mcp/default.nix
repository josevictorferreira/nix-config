{ lib, system, ... }:
let
  isDarwin = builtins.match ".*-darwin" system != null;

in
{
  imports = [
    ./playwright.nix
    ./context7.nix
    ./chrome-devtools.nix
    ./shadcn.nix
    ./ck.nix
    ./podman-mcp.nix
  ]
  ++ lib.optional (!isDarwin) ./mcp-nixos.nix;
}
