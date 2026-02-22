# Aspect: ai-tools
# Main AI Tools aggregator. Enables the entire AI tooling subsystem.
# Imports sub-aspects (rules, scripts) and still-legacy sub-modules
# (mcp, agents, commands, skills) until they are migrated.
{ ... }:
let
  mkOptions =
    { lib, ... }:
    {
      options.jvf.aiTools = {
        enable = lib.mkEnableOption "AI Tools subsystem";
      };
    };

  mkConfig =
    { isDarwin }:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jvf.aiTools;
    in
    {
      imports = [
        mkOptions
        # Legacy sub-modules not yet migrated to dendritic aspects
        ../legacy/_/common/ai-tools/mcp
        ../legacy/_/common/ai-tools/agents
        ../legacy/_/common/ai-tools/commands
        ../legacy/_/common/ai-tools/skills
      ];

      config = lib.mkIf cfg.enable { };
    };
in
{
  flake.modules.nixos.ai-tools = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools = mkConfig { isDarwin = true; };
}
