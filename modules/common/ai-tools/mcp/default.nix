{ lib, ... }:
{
  imports = [
    ./playwright.nix
    ./context7.nix
    ./mcp-nixos.nix
    ./chrome-devtools.nix
    ./shadcn.nix
    ./podman-mcp.nix
  ];
}
