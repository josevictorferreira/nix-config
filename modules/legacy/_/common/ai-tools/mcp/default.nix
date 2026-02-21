{ lib, system, ... }:
let
  isDarwin = builtins.match ".*-darwin" system != null;
in
{
  imports = [
    # ./playwriter.nix
    # ./context7.nix
    # ./chrome-devtools.nix
    # ./shadcn.nix
    ./zai-mcp-server.nix
    # ./web-reader.nix
    # ./web-search-prime.nix
    # ./zread.nix
  ];
  # ++ lib.optional (!isDarwin) ./mcp-nixos.nix;
}
