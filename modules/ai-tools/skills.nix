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

      pythonEnv = pkgs.python3.withPackages (
        ps: with ps; [
          ps."curl-cffi"
          ps.beautifulsoup4
          ps.cryptography
          ps.pyyaml
          ps.secretstorage
          ps.feedparser
        ]
      );
      browserSkillPackages = [
        pkgs.nodejs
        pkgs.curl
        pkgs.gh
        pkgs.yt-dlp
        pkgs.agent-browser
        pkgs.mcporter
        pythonEnv
        pkgs.playwright
      ];

      browserDevCycleScripts = {
        "network-mock.mjs" = pkgs.writeText "browser-dev-cycle-network-mock.mjs" (
          builtins.replaceStrings [ "from 'playwright-core';" ] [ "from '${pkgs.playwright}/index.mjs';" ] (
            builtins.readFile ./_/skills/browser/_/browser-dev-cycle/scripts/network-mock.mjs
          )
        );
        "playwright-helper.mjs" = pkgs.writeText "browser-dev-cycle-playwright-helper.mjs" (
          builtins.replaceStrings [ "from 'playwright-core';" ] [ "from '${pkgs.playwright}/index.mjs';" ] (
            builtins.readFile ./_/skills/browser/_/browser-dev-cycle/scripts/playwright-helper.mjs
          )
        );
        "viewport-test.mjs" = pkgs.writeText "browser-dev-cycle-viewport-test.mjs" (
          builtins.replaceStrings [ "from 'playwright-core';" ] [ "from '${pkgs.playwright}/index.mjs';" ] (
            builtins.readFile ./_/skills/browser/_/browser-dev-cycle/scripts/viewport-test.mjs
          )
        );
      };
      ultimateSkillDir = ./_/skills/browser/_/ultimate-browsing;
      ultimateRuntime = pkgs.runCommand "ultimate-browsing-runtime" { } ''
        mkdir -p "$out"
        cp -r ${ultimateSkillDir}/engine "$out/engine"
        cp -r ${ultimateSkillDir}/scripts "$out/scripts"
        substituteInPlace "$out"/engine/templates/*.js --replace-fail "require('playwright')" "require('${pkgs.playwright}/index.js')"
      '';
      browserDevCycleLoader = pkgs.writeText "browser-dev-cycle-playwright-loader.mjs" ''
        export async function resolve(specifier, context, nextResolve) {
          if (specifier === "playwright-core") {
            return {
              url: "file://${pkgs.playwright}/index.mjs",
              shortCircuit: true,
            };
          }
          return nextResolve(specifier, context);
        }
      '';
      browserRuntimePath = lib.makeBinPath browserSkillPackages;
      browserDevCycleNode = pkgs.writeShellScriptBin "browser-dev-cycle-node" ''
        exec ${lib.getExe pkgs.nodejs} --experimental-loader ${browserDevCycleLoader} "$@"
      '';
      browserDevCycleNetworkMock = pkgs.writeShellScriptBin "browser-dev-cycle-network-mock" ''
        exec ${browserDevCycleNode}/bin/browser-dev-cycle-node ${
          browserDevCycleScripts."network-mock.mjs"
        } "$@"
      '';
      browserDevCyclePlaywrightHelper = pkgs.writeShellScriptBin "browser-dev-cycle-playwright-helper" ''
        exec ${browserDevCycleNode}/bin/browser-dev-cycle-node ${
          browserDevCycleScripts."playwright-helper.mjs"
        } "$@"
      '';
      browserDevCycleViewportTest = pkgs.writeShellScriptBin "browser-dev-cycle-viewport-test" ''
        exec ${browserDevCycleNode}/bin/browser-dev-cycle-node ${
          browserDevCycleScripts."viewport-test.mjs"
        } "$@"
      '';
      ultimateBrowsing = pkgs.writeShellScriptBin "ultimate-browsing" ''
        export PATH="${browserRuntimePath}:$PATH"
        export PYTHONPATH="${ultimateRuntime}:$PYTHONPATH"
        exec ${pythonEnv}/bin/python3 -m engine "$@"
      '';
      ultimateBrowsingCookies = pkgs.writeShellScriptBin "ultimate-browsing-cookies" ''
        export PATH="${browserRuntimePath}:$PATH"
        exec ${pythonEnv}/bin/python3 ${ultimateRuntime}/scripts/extract_cookies.py "$@"
      '';
      ultimateBrowsingBiasCheck = pkgs.writeShellScriptBin "ultimate-browsing-bias-check" ''
        export PATH="${browserRuntimePath}:$PATH"
        exec ${pythonEnv}/bin/python3 ${ultimateRuntime}/engine/bias_check.py "$@"
      '';

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

      config = lib.mkMerge (
        [
          (lib.mkIf (cfg."browser-dev-cycle".enable || cfg."ultimate-browsing".enable) {
            jvf.wrappers.users.${config.jvf.core.username}.programs = {
              browser-skills-runtime.packages = browserSkillPackages;
              browser-dev-cycle-node = {
                command = "${browserDevCycleNode}/bin/browser-dev-cycle-node";
                packages = browserSkillPackages;
              };
              browser-dev-cycle-network-mock = {
                command = "${browserDevCycleNetworkMock}/bin/browser-dev-cycle-network-mock";
                packages = browserSkillPackages;
              };
              browser-dev-cycle-playwright-helper = {
                command = "${browserDevCyclePlaywrightHelper}/bin/browser-dev-cycle-playwright-helper";
                packages = browserSkillPackages;
              };
              browser-dev-cycle-viewport-test = {
                command = "${browserDevCycleViewportTest}/bin/browser-dev-cycle-viewport-test";
                packages = browserSkillPackages;
              };
              ultimate-browsing = {
                command = "${ultimateBrowsing}/bin/ultimate-browsing";
                packages = browserSkillPackages;
              };
              ultimate-browsing-cookies = {
                command = "${ultimateBrowsingCookies}/bin/ultimate-browsing-cookies";
                packages = browserSkillPackages;
              };
              ultimate-browsing-bias-check = {
                command = "${ultimateBrowsingBiasCheck}/bin/ultimate-browsing-bias-check";
                packages = browserSkillPackages;
              };
            };
          })
        ]
        ++ (lib.mapAttrsToList (name: skill: skill.config { inherit config; }) skills)
      );
    };
in
{
  flake.modules.nixos.ai-tools-skills = skillsModule;
  flake.modules.darwin.ai-tools-skills = skillsModule;
}
