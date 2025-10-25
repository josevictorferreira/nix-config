{ lib, ... }:

let
  allFiles = builtins.attrNames (builtins.readDir ./.);

  moduleFiles = (name: name != "default.nix" && lib.hasSuffix ".nix" name) allFiles;

  modules = map (name: ./. + "/${name}") moduleFiles;
in

{
  imports = modules;
}
