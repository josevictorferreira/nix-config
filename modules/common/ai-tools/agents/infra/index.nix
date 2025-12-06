{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./container-expert.nix)
]
