{ lib, ... }:

let
  aiLib = import ../../lib.nix { inherit lib; };
  importCommand = aiLib.importAiFile lib;
in
lib.foldl' lib.recursiveUpdate { } [
  (importCommand ./add-and-format.nix)
  (importCommand ./review.nix)
  (importCommand ./commit-msg.nix)
  (importCommand ./commit-changes.nix)
]
