{ lib, pkgs, ... }:

let
  openCodeDynamicContextPkg = pkgs.buildNpmPackage rec {
    pname = "opencode-dynamic-context-pruning";
    version = "v1.0.3";

    src = pkgs.fetchFromGitHub {
      owner = "Tarquinen";
      repo = "opencode-dynamic-context-pruning";
      rev = "${version}";
      hash = "sha256-rpPeOhUBz+3PXf3w+1h3b98n8/ipi/LOhIH+gSEbiVs=";
    };

    npmDepsHash = "sha256-ipmy0zQySPvW3Ztw7SR1wmcRj7KAqSaXtZg1gjDyugE=";

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
in
{
  config.jvf.programs.opencode.settings.plugin = [
    "${openCodeDynamicContextPkg}/lib/node_modules/@tarquinen/opencode-dcp/dist/index.js"
  ];
}
