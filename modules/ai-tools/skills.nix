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
        auditing-security = import ./skills/auditing/security.nix args;
        creating-skills = import ./skills/meta/creating-skills.nix args;
        research-tools = import ./skills/research/research-tools.nix args;
        grafana = import ./skills/infrastructure/grafana.nix args;
        browser-debug-tools = import ./skills/browser/debug-tools.nix args;
        vision-tools = import ./skills/vision/vision-tools.nix args;
        kubernetes-tools = import ./skills/infrastructure/kubernetes-tools.nix args;
        developing-containers = import ./skills/containers/developing-containers.nix args;
        creating-nix-modules = import ./skills/nix/creating-modules.nix args;
        managing-flakes = import ./skills/nix/managing-flakes.nix args;
        writing-nix-code = import ./skills/nix/writing-code.nix args;
        pythonic-scraping-websites = import ./skills/browser/pythonic-scraping.nix args;
        developing-rails-background-jobs = import ./skills/ruby/rails-background-jobs.nix args;
        developing-rails-event-store = import ./skills/ruby/rails-event-store.nix args;
        developing-rails-scrapers = import ./skills/ruby/rails-scrapers.nix args;
        developing-rspec-tests = import ./skills/ruby/rspec-tests.nix args;
        fixing-rubocop-offenses = import ./skills/ruby/fixing-rubocop.nix args;
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
