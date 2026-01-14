{
  description = "Frontend template using Bun and Vite.js";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        projectPath = toString ./.;
        appName = pkgs.lib.strings.sanitizeDerivationName (builtins.baseNameOf projectPath);

        imageNameFromGit = ''
          git remote get-url origin 2>/dev/null \
            | sed -E 's|.*github\.com[:/]||' \
            | sed 's/\.git$//' \
            || echo "$USER/${appName}"
        '';

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bun
            nodejs_22
            podman
            zsh
            (writeShellScriptBin "keycloak-start" ''
              mkdir -p .dev/keycloak
              echo "Starting Keycloak (User: admin/admin)..."
              podman run --name "${appName}-keycloak" \
                --rm -ti \
                -p 8080:8080 \
                -e KEYCLOAK_ADMIN=admin \
                -e KEYCLOAK_ADMIN_PASSWORD=admin \
                -v "$PWD/.dev/keycloak":/opt/keycloak/data/import \
                quay.io/keycloak/keycloak:latest \
                start-dev --import-realm
            '')
          ];

          shell = pkgs.zsh;

          shellHook = ''
            echo "Frontend development environment loaded for ${appName}"
            echo "Available commands:"
            echo "  bun dev              - Start development server"
            echo "  bun run test         - Run tests in watch mode"
            echo "  bun run test:run     - Run tests once"
            echo "  bun run test:coverage - Run tests with coverage"
            echo "  bun lint             - Run ESLint"
            echo "  bun typecheck        - Run TypeScript type checking"
            echo "  bun build            - Build for production"
            echo "  bun api:generate     - Generate API client from OpenAPI spec"
          '';
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = appName;
          version = "0.0.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [ bun ];

          buildPhase = ''
            export HOME=$(mktemp -d)
            bun install --frozen-lockfile
            bun run build
          '';

          installPhase = ''
            mkdir -p $out
            cp -r dist/* $out/
          '';
        };

        checks.default = pkgs.stdenv.mkDerivation {
          pname = "${appName}-tests";
          version = "0.0.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [ bun ];

          buildPhase = ''
            export HOME=$(mktemp -d)
            bun install --frozen-lockfile
            bun run typecheck
            bun run lint
            bun run test:run
          '';

          installPhase = ''
            mkdir -p $out
            echo "All checks passed" > $out/result
          '';
        };

        packages.build-push = pkgs.writeShellApplication {
          name = "build-push";
          text = ''
            set -e

            REGISTRY="ghcr.io"
            REPO=$(${imageNameFromGit})
            IMAGE_NAME="$REPO"
            TAG="''${REGISTRY}/''${IMAGE_NAME}:latest"

            echo "=== Logging into GitHub Container Registry ==="
            echo "Repository: $REPO"
            echo "Image tag: $TAG"

            if [ -n "''${GITHUB_TOKEN:-}" ]; then
              echo "$GITHUB_TOKEN" | podman login "$REGISTRY" -u "''${GITHUB_USER:-josevictorferreira}" --password-stdin
            else
              echo "Error: GITHUB_TOKEN environment variable is not set"
              exit 1
            fi

            echo ""
            echo "Building and pushing image..."
            podman build \
              --platform=linux/amd64 \
              --file Containerfile \
              --tag "$TAG" \
              .

            podman push "$TAG"

            echo "✓ Image pushed to $TAG"
            echo "You can pull it with: podman pull $TAG"
          '';
        };

        packages.deploy = pkgs.writeShellApplication {
          name = "deploy";
          runtimeInputs = [ ];
          text = ''
            set -e

            REGISTRY="ghcr.io"
            REPO=$(${imageNameFromGit})
            IMAGE_NAME="$REPO"
            TAG="''${REGISTRY}/''${IMAGE_NAME}:latest"

            echo "=== Building and pushing image ==="
            echo "Repository: $REPO"
            echo "Image tag: $TAG"

            if [ -n "''${GITHUB_TOKEN:-}" ]; then
              echo "$GITHUB_TOKEN" | podman login "$REGISTRY" -u "''${GITHUB_USER:-josevictorferreira}" --password-stdin
            else
              echo "Error: GITHUB_TOKEN environment variable is not set"
              exit 1
            fi

            podman build \
              --platform=linux/amd64 \
              --file Containerfile \
              --tag "$TAG" \
              .

            podman push "$TAG"

            if [ -n "''${KUBECONFIG:-}" ]; then
              echo ""
              echo "=== Rolling out deployment ==="
              kubectl --context="''${KUBE_CONTEXT:-default}" -n "''${KUBE_NAMESPACE:-apps}" rollout restart "''${KUBE_DEPLOYMENT:-frontend}"
              kubectl --context="''${KUBE_CONTEXT:-default}" -n "''${KUBE_NAMESPACE:-apps}" rollout status "''${KUBE_DEPLOYMENT:-frontend}" --timeout=300s
            else
              echo "Skipping rollout (KUBECONFIG not set)."
            fi

            echo "✓ Deployment completed"
          '';
        };
      }
    );
}
