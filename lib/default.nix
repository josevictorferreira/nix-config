{
  lib,
  pkgs,
  ...
}:

let
  generators = import ./generators.nix { inherit lib pkgs; };
  filesystem = import ./filesystem.nix { inherit lib pkgs generators; };
in
{
  inherit generators filesystem;
}
