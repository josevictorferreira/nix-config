{ lib
, pkgs
, ...
}:

let
  ohMyOpenCodeVersion = "v3.0.0-beta.13";

  ohMyOpenCodeSrc = pkgs.fetchFromGitHub {
    owner = "code-yeongyu";
    repo = "oh-my-opencode";
    rev = "${ohMyOpenCodeVersion}";
    hash = "sha256-WEw0gYHT0hqCP0A9UyBzveWPXzu73SAs1ZP2wyukgdk=";
  };

  # FOD for bun deps using stdenvNoCC with structured attrs to avoid store path references
  bunDeps = pkgs.stdenvNoCC.mkDerivation {
    pname = "oh-my-opencode-deps";
    version = ohMyOpenCodeVersion;

    src = ohMyOpenCodeSrc;

    nativeBuildInputs = [ pkgs.bun pkgs.cacert ];

    # Required for FOD to work without referencing store paths
    __structuredAttrs = true;
    unsafeDiscardReferences.out = true;

    outputHashMode = "recursive";
    outputHash =
      if pkgs.stdenv.isDarwin
      then "sha256-1xtzQg10stHPpU+VfRY1z4Jc1KIFZ0cdcGEDQcu4NY0="
      else "sha256-smxJ34yvtWcgG8SAaz3q7VLG7v4T8FZ1bukhFCV2TeA=";

    buildPhase = ''
      export HOME=$(mktemp -d)
      bun install
    '';

    installPhase = ''
      rm -rf node_modules/.cache 2>/dev/null || true
      mkdir -p $out
      cp -r node_modules $out/
      cp package.json bun.lock* $out/ 2>/dev/null || true
    '';
  };

  ohMyOpencodePkg = pkgs.stdenv.mkDerivation rec {
    pname = "oh-my-opencode";
    version = ohMyOpenCodeVersion;

    src = ohMyOpenCodeSrc;

    nativeBuildInputs = [
      pkgs.bun
      pkgs.gnused
    ];

    configurePhase = ''
      runHook preConfigure
      cp -r ${bunDeps}/node_modules ./node_modules
      chmod -R u+w node_modules
      # Fix shebangs in node_modules
      find node_modules -type f -executable -print0 | xargs -0 grep -l "^#!/usr/bin/env" 2>/dev/null | while IFS= read -r script; do
        substituteInPlace "$script" --replace "#!/usr/bin/env" "#!${pkgs.coreutils}/bin/env"
      done || true
      patchShebangs node_modules
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      ${lib.getExe pkgs.bun} run build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/node_modules/${pname}
      cp -r dist $out/lib/node_modules/${pname}/
      cp package.json $out/lib/node_modules/${pname}/
      runHook postInstall
    '';

    meta = with lib; {
      description = "Opencode Plugin - Battery Included";
      homepage = "https://github.com/code-yeongyu/oh-my-opencode";
      license = licenses.mit;
      mainProgram = "oh-my-opencode";
    };
  };
in
{
  config.jvf.programs.opencode.ohMyOpenCodeSettings = {
    disabled_commands = [ ];
    agents = {
      Sisyphus = {
        model = "minimax/MiniMax-M2.1";
        temperature = 0.3;
        permission = {
          skill = {
            "*" = {
              "*" = "deny";
              "research-tools" = "allow";
            };
          };
        };
      };
      Sisyphus-Junior = {
        model = "minimax/MiniMax-M2.1";
      };
      Orchestrator-Sisyphus = {
        model = "minimax/MiniMax-M2.1";
        temperature = 0.3;
      };
      librarian = {
        model = "github-copilot/grok-code-fast-1";
        temperature = 0.3;
        permission = {
          skill = {
            "*" = {
              "*" = "deny";
              "research-tools" = "allow";
            };
          };
        };
      };
      explore = {
        model = "github-copilot/grok-code-fast-1";
        temperature = 0.2;
      };
      "Prometheus (Planner)" = {
        model = "github-copilot/gpt-5.2";
        permission = {
          skill = {
            "*" = {
              "*" = "deny";
              "research-tools" = "allow";
            };
          };
        };
      };
      "Metis (Plan Consultant)" = {
        model = "github-copilot/gemini-3-flash-preview";
        permission = {
          skill = {
            "*" = {
              "*" = "deny";
              "research-tools" = "allow";
            };
          };
        };
      };
      "Momus (Plan Reviewer)" = {
        model = "openrouter/moonshotai/kimi-k2-thinking";
      };
      oracle = {
        model = "github-copilot/gpt-5.2";
      };
      frontend-ui-ux-engineer = {
        model = "minimax/MiniMax-M2.1";
      };
      document-writer = {
        model = "openrouter/openai/gpt-oss-120b:exacto";
      };
      multimodal-looker = {
        model = "github-copilot/gemini-3-flash-preview";
      };
    };
    experimental = {
      auto_resume = true;
      dcp_for_compaction = true;
      dynamic_context_pruning = {
        enabled = true;
      };
    };
    ralph_loop = {
      enabled = true;
      default_max_iterations = 1000;
    };
    disabled_hooks = [
      "rules-injector"
    ];
    claude_code = {
      mcp = false;
      commands = false;
      skills = false;
      agents = false;
      hooks = false;
    };
    google_auth = false;
    categories = {
      visual-engineering = {
        model = "github-copilot/gemini-3-pro-preview";
        temperature = 0.7;
      };
      ultrabrain = {
        model = "github-copilot/gpt-5.2";
        temperature = 0.1;
      };
      artistry = {
        model = "github-copilot/gemini-3-pro-preview";
        temperature = 0.9;
      };
      quick = {
        model = "github-copilot/grok-code-fast-1";
        temperature = 0.3;
      };
      most-capable = {
        model = "github-copilot/claude-opus-4.5";
        temperature = 0.1;
      };
      writing = {
        model = "github-copilot/gemini-3-flash-preview";
        temperature = 0.5;
      };
      business-logic = {
        model = "openrouter/moonshotai/kimi-k2-thinking";
        temperature = 0.1;
      };
      general = {
        model = "minimax/MiniMax-M2.1";
        temperature = 0.3;
      };
    };
  };

  config.jvf.programs.opencode.settings.plugin = [
    "${ohMyOpencodePkg}/lib/node_modules/oh-my-opencode/dist/index.js"
    "opencode-antigravity-auth@1.3.1"
    "@tarquinen/opencode-dcp@1.2.7"
    "opencode-toolbox@0.10.4"
    "opencode-mystatus@1.2.4"
  ];

  config.jvf.programs.opencode.commands.mystatus = lib.mkDefault {
    name = "mystatus";
    description = "Query quota usage for all AI accounts";
    prompt = "Use the mystatus tool to query quota usage. Return the result as-is without modification.";
  };
}
