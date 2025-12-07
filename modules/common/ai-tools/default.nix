{ lib, pkgs, system, ... }:

let
  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };
  aiScripts = import ./scripts.nix { inherit lib pkgs; };
  aiLib = import ./lib.nix { inherit lib; };
  aiMcp = import ./mcp.nix { inherit lib pkgs system; };
  aiChecks = import ./checks.nix { inherit lib pkgs system; };
in
{
  commands = aiCommands;
  agents = aiAgents;
  scripts = aiScripts;
  lib = aiLib;
  mcp = aiMcp;
  checks = aiChecks.checks;
  validations = aiChecks.validations;
  stats = aiChecks.stats;
}
