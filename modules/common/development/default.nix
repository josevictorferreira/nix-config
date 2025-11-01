{ pkgs, ... }:

let
  lspServers = import ./lsp-servers.nix { inherit pkgs; };
  formatters = import ./formatters.nix { inherit pkgs; };
  languages = import ./languages.nix { inherit pkgs; };
in
{
  inherit lspServers formatters languages;
}
