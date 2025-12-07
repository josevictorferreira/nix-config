{ lib, ... }:

let
  # Extend lib with our custom mkCommand function for structured commands
  # NOTE: Phase 3 is partially complete - some commands use mkCommand, others are still markdown strings
  aiLib = import ./lib.nix { inherit lib; };
  extendedLib = lib // aiLib;
in
lib.foldl' lib.recursiveUpdate { } [
  (import ./commands/nix/index.nix { lib = extendedLib; })
  (import ./commands/git/index.nix { lib = extendedLib; })
  (import ./commands/quality/index.nix { lib = extendedLib; })
  (import ./commands/project/index.nix { lib = extendedLib; })
  (import ./commands/general/index.nix { lib = extendedLib; })
]
