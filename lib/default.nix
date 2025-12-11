{
  lib,
  pkgs,
  ...
}:

let
  generators = import ./generators.nix { inherit lib pkgs; };
  filesystem = import ./filesystem.nix { inherit lib pkgs generators; };
  git = import ./git.nix { inherit lib pkgs; };
  aiTools = import ./ai-tools.nix { inherit lib pkgs; };
in
{
  inherit
    generators
    filesystem
    git
    aiTools
    ;
}
