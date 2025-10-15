{ lib, ... }:

let
  aiCommands = import ./commands.nix { inherit lib; };
  aiAgents = import ./agents.nix { inherit lib; };
in
{
  commands = aiCommands;
  agents = aiAgents;
}
