{ lib, pkgs, ... }:

let
  openCodeSkillsPkg = pkgs.buildNpmPackage rec {
    pname = "opencode-skills";
    version = "0.1.1";

    src = pkgs.fetchFromGitHub {
      owner = "malhashemi";
      repo = "opencode-skills";
      rev = "v${version}";
      hash = "sha256-VWDtrGuedZLvr9HXVrZbjFQOcRKw3jN6i5+3XUe4TMs=";
    };

    npmDepsHash = "sha256-FlIf4TiEK2QhN+Cyv/7p7BEZa5rGgppVYPwsdgWV2jc=";

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
      description = "Opencode skills plugin";
      homepage = "https://github.com/malhashemi/opencode-skills";
      license = licenses.mit;
      mainProgram = "opencode-skills";
    };
  };
  openCodeDynamicContextPkg = pkgs.buildNpmPackage rec {
    pname = "opencode-dynamic-context-pruning";
    version = "v0.4.17";

    src = pkgs.fetchFromGitHub {
      owner = "Tarquinen";
      repo = "opencode-dynamic-context-pruning";
      rev = "${version}";
      hash = "sha256-nEbt+/70Fhm7zEBq7j7Ay4jwSZNjdfjMNcEX4xfZCug=";
    };

    npmDepsHash = "sha256-Ma2/bgPS1dYz6WXL1FVHKZW1vVbxfVxCGSJNWg9vX9o=";

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
    "${openCodeSkillsPkg}/lib/node_modules/opencode-skills/dist/index.js"
    "${openCodeDynamicContextPkg}/lib/node_modules/@tarquinen/opencode-dcp/dist/index.js"
  ];
}
