# Aspect: ai-tools-commands
# Consolidated AI tools commands module.
# Migrated from modules/legacy/_/common/ai-tools/commands/
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
      inherit (inputs.lib.aiTools) mkCommandModule;

      args = { inherit lib pkgs isDarwin; };

      # Helper to define a command module
      mkCommand =
        path:
        mkCommandModule {
          commandOptions = import path args;
        };

      commands = {
        add-and-format = mkCommand ./_/commands/git/add-and-format.nix;
        commit-changes = mkCommand ./_/commands/git/commit-changes.nix;

        deep-check = mkCommand ./_/commands/general/deep-check.nix;
        dependency-audit = mkCommand ./_/commands/general/dependency-audit.nix;
        style-audit = mkCommand ./_/commands/general/style-audit.nix;
        session-retrospective = mkCommand ./_/commands/general/session-retrospective.nix;
        self-learn = mkCommand ./_/commands/general/self-learn.nix;
        understand-problem = mkCommand ./_/commands/general/understand-problem.nix;
        plan-problem = mkCommand ./_/commands/general/plan-problem.nix;
        execute-problem = mkCommand ./_/commands/general/execute-problem.nix;
        review-problem = mkCommand ./_/commands/general/review-problem.nix;

        homelab-service-update = mkCommand ./_/commands/homelab/homelab-service-update.nix;

        ask = mkCommand ./_/commands/implementation/ask.nix;
        do = mkCommand ./_/commands/implementation/do.nix;
        implement-feature = mkCommand ./_/commands/implementation/implement-feature.nix;
        implement-fix = mkCommand ./_/commands/implementation/implement-fix.nix;
        implement-refactoring = mkCommand ./_/commands/implementation/implement-refactoring.nix;
        implement-tests = mkCommand ./_/commands/implementation/implement-tests.nix;

        flake-update = mkCommand ./_/commands/nix/flake-update.nix;
        nix-check = mkCommand ./_/commands/nix/nix-check.nix;
        nix-module-lint = mkCommand ./_/commands/nix/nix-module-lint.nix;
        nix-module-scaffold = mkCommand ./_/commands/nix/nix-module-scaffold.nix;
        nix-option-migrate = mkCommand ./_/commands/nix/nix-option-migrate.nix;
        nix-refactor = mkCommand ./_/commands/nix/nix-refactor.nix;
        nix-template-new = mkCommand ./_/commands/nix/nix-template-new.nix;

        feat-blueprint = mkCommand ./_/commands/features/feat-blueprint.nix;
        feat-implement = mkCommand ./_/commands/features/feat-implement.nix;
        feat-plan = mkCommand ./_/commands/features/feat-plan.nix;
        feat-research = mkCommand ./_/commands/features/feat-research.nix;
        feat-spec = mkCommand ./_/commands/features/feat-spec.nix;
        feat-tasks = mkCommand ./_/commands/features/feat-tasks.nix;

        rspec-fix = mkCommand ./_/commands/ruby/rspec-fix.nix;
        rubocop-fix = mkCommand ./_/commands/ruby/rubocop-fix.nix;
        rails-frontend-fix = mkCommand ./_/commands/ruby/rails-frontend-fix.nix;
      };

      cfg = config.jvf.aiTools.commands;
    in
    {
      options.jvf.aiTools.commands = lib.mapAttrs (name: cmd: cmd.options) commands;

      config = lib.mkMerge (lib.mapAttrsToList (name: cmd: cmd.config { inherit config; }) commands);
    };
in
{
  flake.modules.nixos.ai-tools-commands = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools-commands = mkConfig { isDarwin = true; };
}
