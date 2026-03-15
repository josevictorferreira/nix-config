# Aspect: ai-tools-agents
# Consolidated AI tools agents module.
# Migrated from modules/legacy/_/common/ai-tools/agents/
_:
let
  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , inputs
    , ...
    }:
    let
      inherit (inputs.lib.aiTools) mkAgentModule;

      args = { inherit lib pkgs isDarwin; };

      # Helper to define an agent module
      mkAgent = path: mkAgentModule {
        agentOptions = import path args;
      };

      agents = {
        ui-ux-architect = mkAgent ./_/agents/design/ui-ux-architect.nix;
        swiss-minimalist-designer = mkAgent ./_/agents/design/swiss-minimalist-designer.nix;
        code-reviewer = mkAgent ./_/agents/general/code-reviewer.nix;
        documentation-writer = mkAgent ./_/agents/general/documentation-writer.nix;
        rails-builder = mkAgent ./_/agents/ruby/rails-builder.nix;
        rails-linter = mkAgent ./_/agents/ruby/rails-linter.nix;
        rails-orchestrator = mkAgent ./_/agents/ruby/rails-orchestrator.nix;
        rails-tester = mkAgent ./_/agents/ruby/rails-tester.nix;
      };

      cfg = config.jvf.aiTools.agents;
    in
    {
      options.jvf.aiTools.agents = lib.mapAttrs (name: agent: agent.options) agents;

      config = lib.mkMerge (
        lib.mapAttrsToList (name: agent: agent.config { inherit config; }) agents
      );
    };
in
{
  flake.modules.nixos.ai-tools-agents = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools-agents = mkConfig { isDarwin = true; };
}
