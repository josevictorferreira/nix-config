{ lib, ... }:

let
  # Extend lib with our custom mkAgent function for structured agents
  # NOTE: Phase 2 is partially complete - some agents use mkAgent, others are still markdown strings
  aiLib = import ./lib.nix { inherit lib; };
  extendedLib = lib // aiLib;
in
lib.foldl' lib.recursiveUpdate { } [
  (import ./agents/nix/index.nix { lib = extendedLib; })
  (import ./agents/project/index.nix { lib = extendedLib; })
  (import ./agents/general/index.nix { lib = extendedLib; })
  (import ./agents/frontend/index.nix { lib = extendedLib; })
  (import ./agents/scraping/index.nix { lib = extendedLib; })
  (import ./agents/rails/index.nix { lib = extendedLib; })
  (import ./agents/infra/index.nix { lib = extendedLib; })
]
