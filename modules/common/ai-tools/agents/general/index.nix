{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./security-auditor.nix { inherit lib; })
  (import ./code-reviewer.nix { inherit lib; })
  (import ./documenter.nix { inherit lib; })
]
