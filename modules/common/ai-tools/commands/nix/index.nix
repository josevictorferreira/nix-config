{ lib, ... }:

let
  aiLib = import ../../lib.nix { inherit lib; };
  importCommand = aiLib.importAiFile lib;
in
lib.foldl' lib.recursiveUpdate { } [
  (importCommand ./refactor.nix)
  (importCommand ./flake-update.nix)
  (importCommand ./module-scaffold.nix)
  (importCommand ./option-migrate.nix)
  (importCommand ./template-new.nix)
  (importCommand ./nix-check.nix)
]
