{ lib
, pkgs
, system ? pkgs.system
, ...
}:

let
  generators = import ./generators.nix { inherit lib pkgs; };
  filesystem = import ./filesystem.nix { inherit lib pkgs generators; };
  git = import ./git.nix { inherit lib pkgs; };
  aiTools = import ./ai-tools.nix { inherit lib pkgs; };
  strings = import ./strings.nix { inherit lib pkgs; };
  sandbox = import ./sandbox.nix { inherit pkgs system; };
in
{
  inherit
    generators
    filesystem
    git
    aiTools
    strings
    sandbox
    ;

  # Direct export for template convenience
  mkSandboxShell = sandbox;
}
