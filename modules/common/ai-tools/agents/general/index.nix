{ lib, ... }:

let
  aiLib = import ../../lib.nix { inherit lib; };
  importAgent = aiLib.importAiFile lib;
in
lib.foldl' lib.recursiveUpdate { } [
  (importAgent ./security-auditor.nix)
  (importAgent ./code-reviewer.nix)
  (importAgent ./documenter.nix)
]
