{ lib, ... }:

let
  aiLib = import ../../lib.nix { inherit lib; };
  importCommand = aiLib.importAiFile lib;
in
lib.foldl' lib.recursiveUpdate { } [
  (importCommand ./ask.nix)
  (importCommand ./do.nix)
  (importCommand ./implement-change.nix)
  (importCommand ./implement-feature.nix)
  (importCommand ./implement-fix.nix)
  (importCommand ./implement-refactoring.nix)
  (importCommand ./implement-tests.nix)
]
