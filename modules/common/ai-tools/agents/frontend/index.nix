{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./shadcn-ui-architect.nix)
  (import ./ui-ux-architect.nix)
]
