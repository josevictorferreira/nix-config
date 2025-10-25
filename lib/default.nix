{ lib, pkgs, ... }:

{
  filesystem = import ./filesystem.nix { inherit lib pkgs; };
}
