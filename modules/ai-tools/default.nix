# Aspect: ai-tools
# Main AI Tools aggregator. Enables the entire AI tooling subsystem.
# Sub-aspects (mcp, agents, commands, skills, rules, scripts) are imported separately.
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
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.aiTools;
    in
    {
      imports = [
        mkOptions
        # Sub-aspects imported separately by host:
        # ai-tools-mcp, ai-tools-agents, ai-tools-commands,
        # ai-tools-skills, ai-tools-rules, ai-tools-scripts
      ];

      config = lib.mkIf cfg.enable { };
    };
in
{
  flake.modules.nixos.ai-tools = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools = mkConfig { isDarwin = true; };
}
