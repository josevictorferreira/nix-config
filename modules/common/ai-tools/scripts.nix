{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./scripts/prompt-enhancer.nix { inherit lib; })
]
