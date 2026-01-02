{ lib
, pkgs
, ...
}:

let
  ohMyOpenCodeVersion = "v2.12.0";

  ohMyOpenCodeSrc = pkgs.fetchFromGitHub {
      owner = "code-yeongyu";
      repo = "oh-my-opencode";
      rev = "${ohMyOpenCodeVersion}";
      hash = "sha256-CGcuoL2xf37LEkpG42xWoF7LCMU9cQ/D5j2RQ3iYNEs=";
    };

  bunDeps = pkgs.stdenv.mkDerivation {
    pname = "oh-my-opencode-deps";
    version = ohMyOpenCodeVersion;

    src = ohMyOpenCodeSrc;

    nativeBuildInputs = [ pkgs.bun ];

    outputHashMode = "recursive";
    outputHash = "sha256-fjq7H9lUdtrYM42nx6ZsQqZpkyj0dLCRPinONUqcyPU=";

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
  ];
}
