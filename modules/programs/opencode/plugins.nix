{ lib
, pkgs
, ...
}:

let
  ohMyOpenCodeVersion = "v2.13.1";

  ohMyOpenCodeSrc = pkgs.fetchFromGitHub {
    owner = "code-yeongyu";
    repo = "oh-my-opencode";
    rev = "${ohMyOpenCodeVersion}";
    hash = "sha256-oZb78jzIWhku+TrKuiq/K42lGwRzBnTusn4wVQNQ2Wg=";
  };

  bunDeps = pkgs.stdenv.mkDerivation {
    pname = "oh-my-opencode-deps";
    version = ohMyOpenCodeVersion;

    src = ohMyOpenCodeSrc;

    nativeBuildInputs = [ pkgs.bun ];

    outputHashMode = "recursive";
    outputHash =
      if pkgs.stdenv.isDarwin
      then "sha256-rWC7wl8sci/UvZ4VDWgAUQReZzqlSS3Mo8zPEQWNooQ="
      else "sha256-7EHfXIifgUSHOpM7i9fk2J7BzRbGGCFXOeoiSLhVLJQ=";

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
  config.jvf.programs.opencode.ohMyOpenCodeSettings = {
    disabled_commands = [ ];
    google_auth = false;
    agents = {
      Sisyphus = {
        model = "google/antigravity-claude-opus-4-5-thinking-low";
      };
      librarian = {
        model = "zai/GLM-4.5-air";
      };
      explore = {
        model = "zai/GLM-4.5-air";
        temperature = 0.2;
      };
      oracle = {
        model = "google/antigravity-claude-opus-4-5-thinking-high";
      };
      frontend-ui-ux-engineer = {
        model = "google/antigravity-gemini-3-pro-high";
      };
      document-writer = {
        model = "minimax/MiniMax-M2.1";
      };
      multimodal-looker = {
        model = "google/antigravity-gemini-3-flash";
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

  config.jvf.programs.opencode.settings.plugin = [
    "${ohMyOpencodePkg}/lib/node_modules/oh-my-opencode/dist/index.js"
    "opencode-antigravity-auth@1.2.7"
    "@tarquinen/opencode-dcp@1.1.3"
  ];
}
