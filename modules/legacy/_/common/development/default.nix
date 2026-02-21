{ pkgs, ... }:

let
  lspServers = (import ./lsp-servers.nix { inherit pkgs; }).packages;
  formatters = (import ./formatters.nix { inherit pkgs; }).packages;
  languages = (import ./languages.nix { inherit pkgs; }).packages;
in
{
  inherit lspServers formatters languages;
}
