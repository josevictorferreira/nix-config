{ lib
, pkgs
, ...
}:

let
  ohMyOpenCodeVersion = "v3.0.0-beta.2";

  ohMyOpenCodeSrc = pkgs.fetchFromGitHub {
    owner = "code-yeongyu";
    repo = "oh-my-opencode";
    rev = "${ohMyOpenCodeVersion}";
    hash = "sha256-00weqPMFyRrpXexQgMngGSha8jAmnDp/CvDczalQwL8=";
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
      then "sha256-iTkeDP3hujleUrpFfUJ6McKfFTEi5hxa8kWocbHSo+k="
      else "sha256-g+oMAyqm0neiz8kheBibOV3ooCCi02HeFc4JAXr/bNQ=";

    buildPhase = ''
      export HOME=$(mktemp -d)
      bun install --frozen-lockfile
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
    google_auth = false;
    agents = {
      Sisyphus = {
        model = "minimax/MiniMax-M2";
        tools = {
          "context7*" = true;
          "ck*" = false;
          "chrome-devtools*" = false;
          "playwriter*" = false;
          "grep_app*" = false;
          "mcp-nixos*" = false;
          "shadcn*" = false;
          "websearch*" = false;
        };
        permission = {
          skill = {
            "fixing-rubocop" = "allow";
          };
        };
      };
      librarian = {
        model = "openrouter/openai/gpt-oss-120b";
        tools = {
          "context7*" = true;
          "ck*" = false;
          "chrome-devtools*" = false;
          "playwriter*" = false;
          "grep_app*" = true;
          "mcp-nixos*" = true;
          "shadcn*" = true;
          "websearch*" = true;
        };
      };
      explore = {
        model = "openrouter/openai/gpt-oss-120b:exacto";
        temperature = 0.3;
        tools = {
          "context7*" = false;
          "ck*" = true;
          "chrome-devtools*" = false;
          "playwriter*" = false;
          "grep_app*" = false;
          "mcp-nixos*" = false;
          "shadcn*" = false;
          "websearch*" = false;
        };
      };
      oracle = {
        model = "zai/GLM-4.7";
        tools = {
          "context7*" = true;
          "ck*" = true;
          "chrome-devtools*" = false;
          "playwriter*" = false;
          "grep_app*" = true;
          "mcp-nixos*" = true;
          "shadcn*" = true;
          "websearch*" = true;
        };
      };
      frontend-ui-ux-engineer = {
        model = "minimax/MiniMax-M2.1";
        tools = {
          "context7*" = true;
          "ck*" = false;
          "chrome-devtools*" = true;
          "playwriter*" = true;
          "grep_app*" = true;
          "mcp-nixos*" = false;
          "shadcn*" = true;
          "websearch*" = true;
        };
      };
      document-writer = {
        model = "openrouter/openai/gpt-oss-120b:exacto";
        tools = {
          "context7*" = false;
          "ck*" = false;
          "chrome-devtools*" = false;
          "playwriter*" = false;
          "grep_app*" = false;
          "mcp-nixos*" = false;
          "shadcn*" = false;
          "websearch*" = false;
        };
      };
      multimodal-looker = {
        model = "zai/GLM-4.6V";
        tools = {
          "context7*" = false;
          "ck*" = false;
          "chrome-devtools*" = false;
          "playwriter*" = false;
          "grep_app*" = false;
          "mcp-nixos*" = false;
          "shadcn*" = false;
          "websearch*" = true;
        };
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
  };

  config.jvf.programs.opencode.settings.plugin = [
    "${ohMyOpencodePkg}/lib/node_modules/oh-my-opencode/dist/index.js"
    "opencode-antigravity-auth@1.2.8"
    "@tarquinen/opencode-dcp@1.1.4"
  ];
}
