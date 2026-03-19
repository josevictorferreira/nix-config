# Aspect: ai-tools-skills
# Consolidated AI tools skills module.
# Migrated from modules/legacy/_/common/ai-tools/skills/
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
      inherit (inputs.lib.aiTools) mkSkillModule;

      npx = lib.getExe' pkgs.nodejs "npx";
      defaultBrowser = if isDarwin then lib.getExe pkgs.google-chrome else lib.getExe pkgs.chromium;

      kebabToHuman = s:
        lib.concatStringsSep " " (map
          (w:
            let
              first = builtins.substring 0 1 w;
              rest = builtins.substring 1 (-1) w;
            in
            (lib.toUpper first) + rest)
          (lib.splitString "-" s));

      args = { inherit lib pkgs isDarwin npx defaultBrowser kebabToHuman; };

      # Helper to define a skill module
      mkSkill = path: mkSkillModule {
        skillOptions = import path args;
      };

      skills = {
        auditing-security = mkSkill ./_/skills/auditing/security.nix;
        creating-skills = mkSkill ./_/skills/meta/creating-skills.nix;
        research-tools = mkSkill ./_/skills/research/research-tools.nix;
        oh-my-claudecode = mkSkill ./_/skills/claudecode/oh-my-claudecode.nix;
        grafana = mkSkill ./_/skills/infrastructure/grafana.nix;
        browser-debug-tools = mkSkill ./_/skills/browser/debug-tools.nix;
        vision-tools = mkSkill ./_/skills/vision/vision-tools.nix;
        kubernetes-tools = mkSkill ./_/skills/infrastructure/kubernetes-tools.nix;
        developing-containers = mkSkill ./_/skills/containers/developing-containers.nix;
        creating-nix-modules = mkSkill ./_/skills/nix/creating-modules.nix;
        managing-flakes = mkSkill ./_/skills/nix/managing-flakes.nix;
        writing-nix-code = mkSkill ./_/skills/nix/writing-code.nix;
        pythonic-scraping-websites = mkSkill ./_/skills/browser/pythonic-scraping.nix;
        developing-rails-background-jobs = mkSkill ./_/skills/ruby/rails-background-jobs.nix;
        developing-rails-event-store = mkSkill ./_/skills/ruby/rails-event-store.nix;
        developing-rails-scrapers = mkSkill ./_/skills/ruby/rails-scrapers.nix;
        developing-rspec-tests = mkSkill ./_/skills/ruby/rspec-tests.nix;
        fixing-rubocop-offenses = mkSkill ./_/skills/ruby/fixing-rubocop.nix;
      };

      cfg = config.jvf.aiTools.skills;
    in
    {
      options.jvf.aiTools.skills = lib.mapAttrs (name: skill: skill.options) skills;

      config = lib.mkMerge (
        lib.mapAttrsToList (name: skill: skill.config { inherit config; }) skills
      );
    };
in
{
  flake.modules.nixos.ai-tools-skills = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools-skills = mkConfig { isDarwin = true; };
}
