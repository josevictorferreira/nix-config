{ lib, pkgs, ... }:

{
  filesystem = import ./filesystem.nix { inherit lib pkgs; };
  generators = import ./generators.nix { inherit lib pkgs; };
}
