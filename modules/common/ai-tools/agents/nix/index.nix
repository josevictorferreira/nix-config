{ lib, ... }:

let
  aiLib = import ../../lib.nix { inherit lib; };
  importAgent = aiLib.importAiFile lib;
in
lib.foldl' lib.recursiveUpdate { } [
  (importAgent ./module-expert.nix)
  (importAgent ./flake-expert.nix)
  (importAgent ./nix-expert.nix)
]
