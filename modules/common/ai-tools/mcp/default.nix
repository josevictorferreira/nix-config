{ lib, system, ... }:
let
  isDarwin = builtins.match ".*-darwin" system != null;

in
{
  imports = [
    ./playwriter.nix
    ./context7.nix
    ./chrome-devtools.nix
    ./shadcn.nix
    ./ck.nix
  ]
  ++ lib.optional (!isDarwin) ./mcp-nixos.nix;
}
