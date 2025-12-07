{ lib, ... }:

let
  aiLib = import ../../lib.nix { inherit lib; };
  importCommand = aiLib.importAiFile lib;
in
lib.foldl' lib.recursiveUpdate { } [
  (importCommand ./changelog.nix)
]
