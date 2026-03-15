# Aspect: ai-tools-skills
# Consolidated AI tools skills module.
# Migrated from modules/legacy/_/common/ai-tools/skills/
_:
let
  mkConfig =
    { isDarwin }:
    { lib
    , pkgs
    , ...
    }:
    let
      programs = [
        "opencode"
        "claudecode"
        "droid"
        "gemini"
      ];

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

      mkSkillConfig = skillName: skillOptions:
        lib.mkMerge (
          map (program: { jvf.programs.${program}.skills.${skillName} = skillOptions; }) programs
        );

      args = { inherit lib pkgs isDarwin npx defaultBrowser kebabToHuman; };

      skills = {
        auditing-security = import ./_/skills/auditing/security.nix args;
        creating-skills = import ./_/skills/meta/creating-skills.nix args;
        research-tools = import ./_/skills/research/research-tools.nix args;
        grafana = import ./_/skills/infrastructure/grafana.nix args;
        browser-debug-tools = import ./_/skills/browser/debug-tools.nix args;
        vision-tools = import ./_/skills/vision/vision-tools.nix args;
        kubernetes-tools = import ./_/skills/infrastructure/kubernetes-tools.nix args;
        developing-containers = import ./_/skills/containers/developing-containers.nix args;
        creating-nix-modules = import ./_/skills/nix/creating-modules.nix args;
        managing-flakes = import ./_/skills/nix/managing-flakes.nix args;
        writing-nix-code = import ./_/skills/nix/writing-code.nix args;
        pythonic-scraping-websites = import ./_/skills/browser/pythonic-scraping.nix args;
        developing-rails-background-jobs = import ./_/skills/ruby/rails-background-jobs.nix args;
        developing-rails-event-store = import ./_/skills/ruby/rails-event-store.nix args;
        developing-rails-scrapers = import ./_/skills/ruby/rails-scrapers.nix args;
        developing-rspec-tests = import ./_/skills/ruby/rspec-tests.nix args;
        fixing-rubocop-offenses = import ./_/skills/ruby/fixing-rubocop.nix args;
      };

    in
    {
      options.jvf.aiTools.skills = { };

      config = lib.mkMerge (
        lib.mapAttrsToList (name: options: mkSkillConfig name options) skills
      );
    };
in
{
  flake.modules.nixos.ai-tools-skills = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools-skills = mkConfig { isDarwin = true; };
}
