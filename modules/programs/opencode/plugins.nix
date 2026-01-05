{ lib
, pkgs
, ...
}:

let
  ohMyOpenCodeVersion = "v2.12.4";

  ohMyOpenCodeSrc = pkgs.fetchFromGitHub {
    owner = "code-yeongyu";
    repo = "oh-my-opencode";
    rev = "${ohMyOpenCodeVersion}";
    hash = "sha256-Gbxgk5+Z2OJ8QLqXXO7GJAe6Af+xoi+0n8uR90IVFSw=";
  };

  bunDeps = pkgs.stdenv.mkDerivation {
    pname = "oh-my-opencode-deps";
    version = ohMyOpenCodeVersion;

    src = ohMyOpenCodeSrc;

    nativeBuildInputs = [ pkgs.bun ];

    outputHashMode = "recursive";
    outputHash =
      if pkgs.stdenv.isDarwin
      then "sha256-Sh4ABJqzIdwBBQg40CXc6sEUsXVvSbSO/RUuMw7Ia/E="
      else "sha256-PQN24HLJjCWw0mKBoOOkr2Z+Hk9nfEJKojZMX5/+s2Y=";

    buildPhase = ''
      runHook preBuild
      ${lib.getExe pkgs.bun} install --frozen-lockfile
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      rm -rf node_modules/.cache 2>/dev/null || true
      mkdir -p $out
      cp -r node_modules $out/
      cp package.json bun.lock* $out/ 2>/dev/null || true
      runHook postInstall
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

    preBuild = ''
      cp -r ${bunDeps}/node_modules ./node_modules
      cp ${bunDeps}/package.json ./package.json 2>/dev/null || true
      find node_modules -type f -executable -print0 | xargs -0 grep -l "^#!/usr/bin/env" 2>/dev/null | while IFS= read -r script; do
        substituteInPlace "$script" --replace "#!/usr/bin/env" "#!${pkgs.coreutils}/bin/env"
      done || true
      # Use patchShebangs to handle all shebang patterns including symlinks
      patchShebangs node_modules
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
  config.jvf.programs.opencode.settings.plugin = [
    "${ohMyOpencodePkg}/lib/node_modules/oh-my-opencode/dist/index.js"
    "opencode-google-antigravity-auth@0.2.12"
    "@tarquinen/opencode-dcp@latest"
  ];

  config.jvf.programs.opencode.ohMyOpenCodeSettings = {
    disabled_commands = [ ];
    agents = {
      Sisyphus = {
        model = "zai/GLM-4.7";
      };
      librarian = {
        model = "openrouter/x-ai/grok-code-fast-1";
      };
      explore = {
        model = "openrouter/openai/gpt-oss-120b:exacto";
        temperature = 0.2;
      };
      oracle = {
        model = "zai/GLM-4.7";
      };
      frontend-ui-ux-engineer = {
        model = "minimax/MiniMax-M2.1";
      };
      document-writer = {
        model = "openrouter/openai/gpt-oss-120b:exacto";
      };
      multimodal-looker = {
        model = "zai/GLM-4.6V";
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
      default_max_iterations = 100;
    };
  };
}
