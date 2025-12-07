{ lib, ... }:

lib.foldl' lib.recursiveUpdate { } [
  (import ./module-expert.nix { inherit lib; })
  (import ./flake-expert.nix { inherit lib; })
  (import ./nix-expert.nix { inherit lib; })
]
