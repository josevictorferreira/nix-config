{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./shadcn-ui-architect.nix { inherit lib; })
  (import ./ui-ux-architect.nix { inherit lib; })
]
