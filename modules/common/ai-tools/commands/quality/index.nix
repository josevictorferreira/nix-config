{ lib, ... }:

let
  aiLib = import ../../lib.nix { inherit lib; };
  importCommand = aiLib.importAiFile lib;
in
lib.foldl' lib.recursiveUpdate { } [
  (importCommand ./quick-check.nix)
  (importCommand ./deep-check.nix)
  (importCommand ./style-audit.nix)
  (importCommand ./dependency-audit.nix)
  (importCommand ./module-lint.nix)
]
