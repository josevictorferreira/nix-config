{ lib, pkgs, ... }:

let
  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };
  aiScripts = import ./scripts.nix { inherit lib pkgs; };
  aiLib = import ./lib.nix { inherit lib; };
in
{
  commands = aiCommands;
  agents = aiAgents;
  scripts = aiScripts;
  lib = aiLib;
  mcp = aiMcp;
}
