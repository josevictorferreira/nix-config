{ lib, pkgs, system }:

let
  mcpDir = ./mcp;
  mcpFiles = builtins.filter (file: lib.hasSuffix ".nix" file) (builtins.attrNames (builtins.readDir mcpDir));
in
lib.foldl' lib.recursiveUpdate { } (builtins.map (file: import (mcpDir + "/${file}") { inherit lib pkgs system; }) mcpFiles)
