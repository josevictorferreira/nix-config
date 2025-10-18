{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./shadcn-ui-architect.md)
  (import ./ui-ux-architect.md)
]
