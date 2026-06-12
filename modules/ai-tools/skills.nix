# Aspect: ai-tools-skills
# Consolidated AI tools skills module.
# Migrated from modules/legacy/_/common/ai-tools/skills/
_:
let
  skillsModule =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      inherit (inputs.lib.aiTools) mkSkillModule;

      npx = lib.getExe' pkgs.nodejs "npx";
      defaultBrowser = lib.getExe pkgs.brave;

      kebabToHuman =
        s:
        lib.concatStringsSep " " (
          map (
            w:
            let
              first = builtins.substring 0 1 w;
              rest = builtins.substring 1 (-1) w;
            in
            (lib.toUpper first) + rest
          ) (lib.splitString "-" s)
        );

      args = {
        inherit
          lib
          pkgs
          npx
          defaultBrowser
          kebabToHuman
          ;
        isDarwin = pkgs.stdenv.isDarwin;
      };

      # Helper to define a skill module
      mkSkill =
        path:
        mkSkillModule {
          skillOptions = import path args;
        };

      skills = {
        auditing-security = mkSkill ./_/skills/auditing/security.nix;
        creating-skills = mkSkill ./_/skills/meta/creating-skills.nix;
        skill-creator = mkSkill ./_/skills/meta/skill-creator.nix;
        xlsx = mkSkill ./_/skills/meta/xlsx.nix;
        karpathy-guidelines = mkSkill ./_/skills/meta/karpathy-guidelines.nix;
        research-tools = mkSkill ./_/skills/research/research-tools.nix;
        oh-my-claudecode = mkSkill ./_/skills/claudecode/oh-my-claudecode.nix;
        grafana = mkSkill ./_/skills/infrastructure/grafana.nix;
        # openclaw-nix-upgrade = mkSkill ./_/skills/infrastructure/openclaw-nix-upgrade.nix;
        openclaw-upgrade = mkSkill ./_/skills/infrastructure/openclaw-upgrade.nix;
        browser-debug-tools = mkSkill ./_/skills/browser/debug-tools.nix;
        browser-dev-cycle = mkSkill ./_/skills/browser/browser-dev-cycle.nix;
        vision-tools = mkSkill ./_/skills/vision/vision-tools.nix;
        kubernetes-tools = mkSkill ./_/skills/infrastructure/kubernetes-tools.nix;
        developing-containers = mkSkill ./_/skills/containers/developing-containers.nix;
        creating-nix-modules = mkSkill ./_/skills/nix/creating-modules.nix;
        maintaining-dendritic-nix-config = mkSkill ./_/skills/nix/maintaining-dendritic-nix-config.nix;
        managing-flakes = mkSkill ./_/skills/nix/managing-flakes.nix;
        writing-nix-code = mkSkill ./_/skills/nix/writing-code.nix;
        kubenix-code = mkSkill ./_/skills/nix/kubenix-code.nix;
        pythonic-scraping-websites = mkSkill ./_/skills/browser/pythonic-scraping.nix;
        developing-rails-background-jobs = mkSkill ./_/skills/ruby/rails-background-jobs.nix;
        developing-rails-event-store = mkSkill ./_/skills/ruby/rails-event-store.nix;
        developing-rails-scrapers = mkSkill ./_/skills/ruby/rails-scrapers.nix;
        developing-rspec-tests = mkSkill ./_/skills/ruby/rspec-tests.nix;
        fixing-rubocop-offenses = mkSkill ./_/skills/ruby/fixing-rubocop.nix;
        gleam-deployment = mkSkill ./_/skills/gleam/deployment.nix;
        gleam-erlang-interop = mkSkill ./_/skills/gleam/erlang-interop.nix;
        gleam-javascript-interop = mkSkill ./_/skills/gleam/javascript-interop.nix;
        gleam-lustre-development = mkSkill ./_/skills/gleam/lustre-development.nix;
        gleam-otp-development = mkSkill ./_/skills/gleam/otp-development.nix;
        gleam-package-development = mkSkill ./_/skills/gleam/package-development.nix;
        gleam-testing = mkSkill ./_/skills/gleam/testing.nix;
        gleam-web-development = mkSkill ./_/skills/gleam/web-development.nix;
        gleam-actor-model = mkSkill ./_/skills/gleam/actor-model.nix;
        gleam-conventions = mkSkill ./_/skills/gleam/conventions.nix;
      };

      cfg = config.jvf.aiTools.skills;
    in
    {
      options.jvf.aiTools.skills = lib.mapAttrs (name: skill: skill.options) skills;

      config = lib.mkMerge (lib.mapAttrsToList (name: skill: skill.config { inherit config; }) skills);
    };
in
{
  flake.modules.nixos.ai-tools-skills = skillsModule;
  flake.modules.darwin.ai-tools-skills = skillsModule;
}
