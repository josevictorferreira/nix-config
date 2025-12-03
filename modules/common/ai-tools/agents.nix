{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./agents/nix/index.nix { inherit lib; })
  (import ./agents/project/index.nix { inherit lib; })
  (import ./agents/general/index.nix { inherit lib; })
  (import ./agents/frontend/index.nix { inherit lib; })
  (import ./agents/scraping/index.nix { inherit lib; })
  (import ./agents/rails/index.nix { inherit lib; })
]
