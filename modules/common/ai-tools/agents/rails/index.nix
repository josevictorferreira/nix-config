{ lib, ... }:

let
  aiLib = import ../../lib.nix { inherit lib; };
  importAgent = aiLib.importAiFile lib;
in
lib.foldl' lib.recursiveUpdate { } [
  (importAgent ./rails-event-store-specialist.nix)
]
