{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./rails-event-store-specialist.nix { inherit lib; })
]
