{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./system-config-expert.nix { inherit lib; })
]
