{ lib, pkgs, ... }:

let
  # Import all script modules from the scripts directory
  scriptModules = {
    prompt-enhancer = import ./scripts/prompt-enhancer.nix { inherit lib pkgs; };
    # Add future scripts here as: script-name = import ./scripts/script-name.nix { inherit lib pkgs; };
  };
in
scriptModules
