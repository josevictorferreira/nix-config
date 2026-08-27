# Aspect: ai-tools-skills
# Consolidated AI tools skills module.
# Migrated from modules/legacy/_/common/ai-tools/skills/
_:
let
  skillsModule =
    { config
    , lib
    , pkgs
    , inputs
    , ...
    }:
    let
      inherit (inputs.lib.aiTools) mkSkillModule;

      npx = lib.getExe' pkgs.nodejs "npx";
      defaultBrowser = lib.getExe pkgs.brave;

      kebabToHuman =
        s:
        lib.concatStringsSep " " (
          map
            (
              w:
              let
                first = builtins.substring 0 1 w;
                rest = builtins.substring 1 (-1) w;
              in
              (lib.toUpper first) + rest
            )
            (lib.splitString "-" s)
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
        creating-skills = mkSkill ./_/skills/meta/creating-skills.nix;
        xlsx = mkSkill ./_/skills/meta/xlsx.nix;
        self-learning = mkSkill ./_/skills/meta/self-learning.nix;
        research-tools = mkSkill ./_/skills/research/research-tools.nix;
        implementation-plan-best-practices = mkSkill ./_/skills/planning/implementation-plan-best-practices.nix;
        brainstorming = mkSkill ./_/skills/planning/brainstorming.nix;
        oh-my-claudecode = mkSkill ./_/skills/claudecode/oh-my-claudecode.nix;
        grafana = mkSkill ./_/skills/infrastructure/grafana.nix;
        # openclaw-nix-upgrade = mkSkill ./_/skills/infrastructure/openclaw-nix-upgrade.nix;
        # browser-debug-tools = mkSkill ./_/skills/browser/debug-tools.nix; # Disabled: replaced by browser-dev-cycle
        browser-dev-cycle = mkSkill ./_/skills/browser/browser-dev-cycle.nix;
        ultimate-browsing = mkSkill ./_/skills/browser/ultimate-browsing.nix;
        remove-ai-slops = mkSkill ./_/skills/qa/remove-ai-slops.nix;
        vision-tools = mkSkill ./_/skills/vision/vision-tools.nix;
        adversarial-ux-test = mkSkill ./_/skills/qa/adversarial-ux-test.nix;
        design-md = mkSkill ./_/skills/creative/design-md.nix;
        humanize-text = mkSkill ./_/skills/creative/humanize-text.nix;
        kubernetes-tools = mkSkill ./_/skills/infrastructure/kubernetes-tools.nix;
        developing-containers = mkSkill ./_/skills/containers/developing-containers.nix;
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
