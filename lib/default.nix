{ lib, ... }:

{
  filesystem = import ./filesystem.nix { inherit lib; };
}
