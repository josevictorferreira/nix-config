{ lib, config ? { }, pkgs ? null, system ? null, ... }:

let
  aiTypes = import ./types.nix { inherit lib; };
  cfg = config.jvf.aiTools or { enable = false; };

  # Legacy exports (pre-module refactor) for backward compatibility
  legacyCommands = import ./commands.nix { inherit lib; };
  legacyAgents = import ./agents.nix { inherit lib; };
  legacyScripts = import ./scripts.nix { inherit lib pkgs; };
  legacyLib = import ./lib.nix { inherit lib; };
  legacyMcp = import ./mcp.nix { inherit lib pkgs system; };
  legacyChecks = import ./checks.nix { inherit lib pkgs system; };
in
{
  options.jvf.aiTools = {
    enable = lib.mkEnableOption "AI tools integration";

    agents = lib.mkOption {
      type = lib.types.attrsOf aiTypes.agentType;
      default = { };
      description = lib.mdDoc "AI agents definitions.";
    };

    commands = lib.mkOption {
      type = lib.types.attrsOf aiTypes.commandType;
      default = { };
      description = lib.mdDoc "AI commands definitions.";
    };

    mcp = lib.mkOption {
      type = lib.types.attrsOf aiTypes.mcpType;
      default = { };
      description = lib.mdDoc "MCP servers definitions.";
    };
  };

  config = lib.mkIf cfg.enable { };

  # Legacy exports retained to avoid breaking existing consumers during migration
  commands = legacyCommands;
  agents = legacyAgents;
  scripts = legacyScripts;
  lib = legacyLib;
  mcp = legacyMcp;
  checks = legacyChecks.checks;
  validations = legacyChecks.validations;
  stats = legacyChecks.stats;
}
