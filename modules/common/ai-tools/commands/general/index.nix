{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./ask.nix)
  (import ./do.nix)
  (import ./implement-change.nix)
  (import ./implement-feature.nix)
  (import ./implement-fix.nix)
  (import ./implement-refactoring.nix)
  (import ./implement-tests.nix)
]
