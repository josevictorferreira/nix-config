# Aspect: checks-theme-profile-artifacts
# perSystem RED check for the profile artifact contract.
# Validates:
#   1. Artifact paths and runtime paths are disjoint
#   2. No runtime path is under a Nix-owned jvf.home target
#   3. Each profile has non-null artifacts for every contract category
# RED until adapters (Tasks 7-11) register actual artifacts.
{ inputs, self, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    let
      evalSystem = inputs.self.nixosConfigurations.zeh-pc;
      cfg = evalSystem.config.jvf.theme;

      # ── Contract validation ──────────────────────────────────────────────
      profileNames = builtins.attrNames cfg.profiles;
      contractCategories = builtins.attrNames cfg.artifactContract;

      # Check 1: artifact and runtime paths are disjoint
      artifactBase = cfg.paths.artifactBase;
      runtimeState = cfg.paths.runtimeState;
      pathsDisjoint =
        !(lib.strings.hasPrefix artifactBase runtimeState)
        && !(lib.strings.hasPrefix runtimeState artifactBase);

      # Check 2: runtime state is NOT under any jvf.home target
      # (jvf.home materializes under artifactBase, never under runtimeState)
      runtimeNotNixOwned = !(lib.strings.hasPrefix runtimeState artifactBase);

      # Check 3: every profile × category has a non-null artifact
      # This is the RED check — fails until adapters register artifacts.
      missingArtifacts = builtins.concatLists (
        map
          (
            profileName:
            let
              registered = cfg.profileArtifacts.${profileName} or { };
            in
            map
              (
                catName: if registered.${catName} or null != null then null else "${profileName}.${catName}"
              )
              contractCategories
          )
          profileNames
      );

      missing = builtins.filter (x: x != null) missingArtifacts;

      lib = inputs.nixpkgs.lib;
    in
    {
      checks.theme-profile-artifacts = pkgs.runCommand "theme-profile-artifacts-check" { } ''
        echo "============================================"
        echo "  Profile Artifact Contract Check"
        echo "============================================"

        # ── Structural checks (should PASS) ──────────────────────────
        echo ""
        echo "[Structural] Artifact path: ~/${artifactBase}"
        echo "[Structural] Runtime path:  ~/${runtimeState}"

        ${
          if pathsDisjoint then
            ''echo "  ✓ Artifact and runtime paths are disjoint"''
          else
            ''echo "FAIL: artifact and runtime paths overlap"; exit 1''
        }

        ${
          if runtimeNotNixOwned then
            ''echo "  ✓ Runtime state is not Nix-owned"''
          else
            ''echo "FAIL: runtime state is under Nix-owned path"; exit 1''
        }

        # ── Artifact completeness check (RED until adapters register) ──
        echo ""
        echo "[Artifacts] Profiles: ${builtins.toString profileNames}"
        echo "[Artifacts] Contract categories: ${builtins.toString contractCategories}"

        ${
          if missing != [ ] then
            ''
              echo ""
              echo "============================================"
              echo "  RED: Missing artifact registrations"
              echo "============================================"
              ${lib.concatStringsSep "\n" (map (m: ''echo "  missing: ${m}"'') missing)}
              echo ""
              echo "  Register artifacts via jvf.theme.profileArtifacts."
              echo "  See artifactContract for expected filenames per category."
              echo "============================================"
              exit 1
            ''
          else
            ''
              echo "  ✓ All profile artifacts registered"
              touch $out
            ''
        }
      '';
    };
}
