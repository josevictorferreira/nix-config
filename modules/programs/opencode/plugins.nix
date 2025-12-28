{
  lib,
  pkgs,
  ...
}:

let
  openCodeDynamicContextPkg = pkgs.buildNpmPackage rec {
    pname = "opencode-dynamic-context-pruning";
    version = "v1.1.2";

    src = pkgs.fetchFromGitHub {
      owner = "Tarquinen";
      repo = "opencode-dynamic-context-pruning";
      rev = "${version}";
      hash = "sha256-dxIAmUX0gSvZW3P4hxQwzbwSm3jBj8fftUO/FYLZTOg=";
    };

    npmDepsHash = "sha256-1pPBmiIY/EwMxa12MvbWk7WfusmxS9eWjlz5VTQ4ICQ=";

    postPatch = ''
      ${lib.getExe pkgs.jq} '
        .dependencies += (.peerDependencies // {}) |
        . as $all | .devDependencies |= with_entries(
          select(.key as $k | ($all.dependencies | has($k) | not))
        ) |
        del(.peerDependencies)
      ' package.json > package-tmp.json && mv package-tmp.json package.json
    '';

    meta = with lib; {
      description = "Opencode Dynamic Context Pruning";
      homepage = "https://github.com/Tarquinen/opencode-dynamic-context-pruning";
      license = licenses.mit;
      mainProgram = "opencode-dynamic-context-pruning";
    };
  };

  # Fixed-output derivation to fetch bun dependencies
  bunDeps = pkgs.stdenv.mkDerivation rec {
    pname = "oh-my-opencode-deps";
    version = "v2.6.2";

    src = pkgs.fetchFromGitHub {
      owner = "code-yeongyu";
      repo = "oh-my-opencode";
      rev = "${version}";
      hash = "sha256-dsUL4nkRi2aa9nmLnSmQlAJ6il7d5teUT4Ap6H+r3mI=";
    };

    nativeBuildInputs = [ pkgs.bun ];

    # This is a fixed-output derivation - it's allowed to download from the internet
    outputHashMode = "recursive";
    outputHash = "sha256-VdG6Oi9gdyYGxwdjn4yWQZoF3L7ksr61/TkDdsQipcU=";

    buildPhase = ''
      runHook preBuild
      ${lib.getExe pkgs.bun} install --frozen-lockfile
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      # Remove .cache directory which contains broken symlinks pointing to /build
      rm -rf node_modules/.cache 2>/dev/null || true
      mkdir -p $out
      cp -r node_modules $out/
      cp package.json bun.lock* $out/ 2>/dev/null || true
      runHook postInstall
    '';
  };

  ohMyOpencodePkg = pkgs.stdenv.mkDerivation rec {
    pname = "oh-my-opencode";
    version = "v2.5.1";

    src = pkgs.fetchFromGitHub {
      owner = "code-yeongyu";
      repo = "oh-my-opencode";
      rev = "${version}";
      hash = "sha256-OCD02WIvRNVfk2Pd/uCBSNuddS8nN2KzxHlAmfFOG64=";
    };

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
    "${openCodeDynamicContextPkg}/lib/node_modules/@tarquinen/opencode-dcp/dist/index.js"
    "${ohMyOpencodePkg}/lib/node_modules/oh-my-opencode/dist/index.js"
  ];
}
