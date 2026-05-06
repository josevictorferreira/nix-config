{
  lib,
  pkgs,
  isDarwin,
  npx,
  defaultBrowser,
  kebabToHuman,
  ...
}:
{
  name = "openclaw-nix-upgrade";
  description = ''
    Complete workflow for upgrading the openclaw-nix container image version in the homelab.
    Use when asked to upgrade, bump, or update the openclaw-nix image, OpenClaw version, or
    openclaw container. Triggers on: "upgrade openclaw", "update openclaw-nix image",
    "bump openclaw version", "new openclaw release", "openclaw v{version}".
  '';
  references = {
    "checks" = ''
      # OpenClaw-Nix Post-Deploy Verification

      Run these checks after the pod is `Running`. Each check must pass before considering the upgrade successful.

      ## 1. Pod Status

      ```bash
      kubectl get pod -n apps -l app.kubernetes.io/name=openclaw-nix -o wide
      ```

      **Expected:** `READY` column shows `2/2`, `STATUS` is `Running`, zero `RESTARTS`.
      If `1/2`: wait — the readiness probe is still evaluating. Check logs.
      If `0/2` + `ImagePullBackOff`: see `references/troubleshooting.md`.

      ## 2. Image Digest

      ```bash
      kubectl get pod -n apps -l app.kubernetes.io/name=openclaw-nix -o jsonpath='{.items[0].status.containerStatuses[?(@.name=="main")].imageID}' | cut -d'@' -f2
      ```

      **Expected:** Matches the pinned digest in `modules/kubenix/apps/openclaw-nix.nix`.
      Compare with: `grep 'tag =' modules/kubenix/apps/openclaw-nix.nix`

      ## 3. Health Endpoint

      ```bash
      kubectl exec -n apps deploy/openclaw-nix -c main -- /bin/curl -m 15 -sS http://127.0.0.1:18789/health
      ```

      **Expected:** `{"ok":true,"status":"live"}`

      ## 4. Gateway Readiness

      ```bash
      kubectl logs -n apps deploy/openclaw-nix -c main --tail=50 | grep -E 'gateway.*ready|http server listening'
      ```

      **Expected:** Contains `[gateway] http server listening` with plugin list and `[gateway] ready`.
      Shows plugins like: `lossless-claw, matrix, memory-lancedb, memory-wiki, whatsapp`.

      ## 5. No Crash Loops

      ```bash
      kubectl get pod -n apps -l app.kubernetes.io/name=openclaw-nix -o jsonpath='{.items[0].status.containerStatuses[?(@.name=="main")].restartCount}'
      ```

      **Expected:** `0` (or low number if just deployed). If > 2 in first 5 minutes, check logs for errors.

      ## 6. Event Audit

      ```bash
      kubectl describe pod -n apps -l app.kubernetes.io/name=openclaw-nix | grep -E 'Pulling|Pulled|Failed|BackOff|Mount'
      ```

      **Expected:**
      - `Normal Pulling` → `Normal Pulled` for both `chromium` and `main` containers
      - No `Failed`, no `BackOff`, no `FailedMount`, no `Multi-Attach`

      ## 7. Matrix Connectivity (if Matrix plugin enabled)

      ```bash
      kubectl logs -n apps deploy/openclaw-nix -c main --tail=100 | grep -E '\[matrix\].*started|\[matrix\].*sync'
      ```

      **Expected:** Matrix plugin logs show active sync, no auth errors.

      ## Checklist Summary

      - [ ] Pod `2/2 Running`
      - [ ] Image digest matches manifest
      - [ ] `/health` returns `{"ok":true,"status":"live"}`
      - [ ] `[gateway] ready` in logs
      - [ ] Restart count ≤ 1
      - [ ] No ImagePull/Mount errors in events
      - [ ] Matrix plugin syncing (if enabled)
    '';
  };
  scripts = { };
  prompt = ''
    # OpenClaw-Nix Image Upgrade

    Complete step-by-step flow for upgrading the `openclaw-nix` OCI container image and deploying
    it to the homelab Kubernetes cluster.

    ## Overview

    This upgrade involves 5 phases:
    1. **Verify upstream** — confirm the target version tag exists
    2. **Update Nix sources** — bump version, resolve hashes, update deps
    3. **Build image** — `nix build .#openclaw-nix-image` with placeholder hashes
    4. **Push to GHCR** — push image, verify remote digest, pin in manifest
    5. **Deploy** — regenerate manifests, apply or reconcile, verify pod

    ## Security Guardrails

    Never run broad `env`, `printenv`, `/proc/*/environ`, full `openclaw.json` dumps, or
    unconstrained `jq paths` on live OpenClaw config.

    OpenClaw config contains Matrix access tokens and provider API keys. Query only explicit
    non-secret fields.

    ## Project Gotchas to Keep in Mind

    - Verify `kubectl config current-context` is `ze-homelab` before every cluster operation.
    - Keep `/home/node/.openclaw` on CephFS `shared-storage` subPath `openclaw`; never migrate it
      to an RBD PVC without explicit approval.
    - Keep `OPENCLAW_PLUGIN_STAGE_DIR` on pod-local storage, not inside the CephFS state tree.
    - Use explicit image version tags plus registry digest pins; never deploy mutable `latest`.
    - If you change probe handler type, inspect Flux dry-run/apply errors for merged old handlers.
      Server-side apply can retain an old `httpGet` when adding a new `tcpSocket`.

    ## Phase 1: Verify Upstream

    ```bash
    # Confirm the upstream release tag exists
    git ls-remote --tags https://github.com/openclaw/openclaw "refs/tags/v{VERSION}"
    ```

    If the tag doesn't exist, the build will fail at fetch time with 404.

    ## Phase 2: Update Nix Sources

    **Files to edit:**

    Trace the whole tag chain before editing to avoid double suffixes:

    ```bash
    grep -rn 'imageTag\|openclawVersion\|tagSuffix\|image.tag\|tag =' flake.nix oci-images/ modules/
    ```

    ### `oci-images/openclaw-nix/default.nix`

    1. Update `version` on line ~6:
       ```nix
       version ? "2026.5.4",  # was "2026.5.3"
       ```

    2. Replace `sha256` with `lib.fakeHash` (32 zeros):
       ```nix
       sha256 = lib.fakeHash;
       ```

    3. Replace `pnpmDepsHash` with `lib.fakeHash`:
       ```nix
       pnpmDepsHash = lib.fakeHash;
       ```

    4. Check Python dependencies (around line 553): add any new deps needed for the new version.

    ### `modules/commands.nix` (line ~558)

    ```nix
    openclawVersion = "{VERSION}";
    ```

    ### Stage files only when needed

    Nix flakes use git state for source discovery. Newly-created files must be staged before
    building, but do not stage unrelated work:
    ```bash
    git add <new-file> ...
    ```

    Existing tracked file edits are visible to the build without staging.

    ### Source-only bundled plugins

    Some bundled OpenClaw plugins exist only under `extensions/<plugin>` with
    `openclaw.plugin.json` pointing to `./index.ts`, and no compiled
    `dist/extensions/<plugin>` output.

    If enabling such a plugin in the image:
    - Copy only runtime TS files into `/lib/openclaw/dist/extensions/<plugin>/`
    - Copy `openclaw.plugin.json` and `package.json`
    - Validate native/runtime imports inside the image

    ```bash
    podman run --rm --entrypoint "" <image> sh -c 'test -f /lib/openclaw/dist/extensions/<plugin>/index.ts && cd /lib/openclaw && node -e "import(\"@lancedb/lancedb\").then(()=>console.log(\"ok\"))"'
    ```

    ## Phase 3: Build Image

    **First build (resolve source hash):**
    ```bash
    nix build .#openclaw-nix-image --show-trace
    ```
    This fails with "hash mismatch" — copy the `sha256-...` from the error.

    **Update sha256** in `oci-images/openclaw-nix/default.nix` with the captured value.

    **Build again (resolve pnpmDepsHash):**
    ```bash
    nix build .#openclaw-nix-image --show-trace
    ```
    This fails again with pnpmDepsHash mismatch — copy `sha256-...` from error.

    **Update pnpmDepsHash**, and build final time:
    ```bash
    nix build .#openclaw-nix-image --show-trace
    ```
    This must succeed. All derivations should build without errors.

    ### Local image smoke tests

    Before pushing, load and validate the built image. Always confirm the main binary and basic
    runtime tools exist after any `/bin` or image contents refactor:

    ```bash
    IMAGE_PATH=$(nix build .#openclaw-nix-image --print-out-paths --no-link)
    "$IMAGE_PATH" | podman load
    LOCAL_TAG=$(podman images localhost/openclaw-nix --format '{{.Tag}}' | grep '^v{VERSION}' | head -1)
    podman run --rm --entrypoint "" localhost/openclaw-nix:"$LOCAL_TAG" sh -c 'which openclaw && openclaw --version && which sed && which cat && which ls'
    ```

    ## Phase 4: Push to GHCR

    ### Run push command
    ```bash
    make push-openclaw
    ```

    **If `make push-openclaw` times out** during the auto-pin step (step 6/6), complete manually:

    ```bash
    # 1. Derive the loaded local tag; do not hardcode tag suffixes
    LOCAL_TAG=$(podman images localhost/openclaw-nix --format '{{.Tag}}' | grep '^v{VERSION}' | head -1)
    test -n "$LOCAL_TAG"

    # 2. Remove stale local GHCR tags to prevent collisions
    podman rmi -f ghcr.io/josevictorferreira/openclaw-nix:latest \
      ghcr.io/josevictorferreira/openclaw-nix:"$LOCAL_TAG" 2>/dev/null || true

    # 3. Log in
    echo "$(gh auth token)" | podman login ghcr.io -u josevictorferreira --password-stdin

    # 4. Tag and push
    podman tag localhost/openclaw-nix:"$LOCAL_TAG" ghcr.io/josevictorferreira/openclaw-nix:latest
    podman tag localhost/openclaw-nix:"$LOCAL_TAG" ghcr.io/josevictorferreira/openclaw-nix:"$LOCAL_TAG"
    podman push --format=oci ghcr.io/josevictorferreira/openclaw-nix:"$LOCAL_TAG"
    podman push --format=oci ghcr.io/josevictorferreira/openclaw-nix:latest

    # 5. Get the REMOTE digest (NOT local!)
    REMOTE_DIGEST=$(nix shell nixpkgs#skopeo -c skopeo inspect \
      --format '{{.Digest}}' \
      docker://ghcr.io/josevictorferreira/openclaw-nix:"$LOCAL_TAG")
    ```

    ### Pin digest in manifest

    ```nix
    # modules/kubenix/apps/openclaw-nix.nix line ~8:
    tag = "<LOCAL_TAG>@<REMOTE_DIGEST>";
    ```

    CRITICAL: Use the REMOTE digest from `skopeo inspect`, NOT the local digest. The local
    digest from `streamLayeredImage` can differ from what the registry computes.

    ## Phase 5: Deploy

    ### Regenerate manifests
    ```bash
    make manifests
    ```

    Verify the generated `.k8s/apps/openclaw-nix.yaml` contains the correct digest (should match
    the remote digest hash you confirmed above).

    Only run the full pipeline. Do not run individual manifest stages (`nix build .#gen-manifests`,
    `vals eval`, etc.) because they can leave `.k8s/` misleading or incomplete.

    If new secret keys or encrypted config keys were added, remove the affected file's stale entry
    from `manifests.lock` and delete that generated `.k8s/...` file before `make manifests`; the
    unlock/restore stage can otherwise restore the old encrypted file.

    ### Validate live OpenClaw config safely

    The real config is `~/Homelab/openclaw/openclaw.json` on CephFS. The Nix configmap is
    fallback/mirror only.

    Do not dump the full config. Use allowlisted structural checks only:

    ```bash
    jq '.channels.matrix.groups | keys' ~/Homelab/openclaw/openclaw.json
    jq '.plugins.slots, (.plugins.entries | keys)' ~/Homelab/openclaw/openclaw.json
    ```

    If startup fails with `Invalid config`, patch the live config surgically and mirror non-secret
    structural changes back to `modules/kubenix/apps/openclaw-config.enc.nix`.

    ### Persist or apply changes

    Do not commit unless the user explicitly asks.

    Flux reconciles from git, not local `.k8s/` output. If changes are not committed and pushed,
    `flux reconcile` will not deploy them.

    If the user wants immediate deployment from uncommitted local changes, apply the generated
    manifest directly:

    ```bash
    kubectl config current-context  # must be ze-homelab
    kubectl apply -f .k8s/apps/openclaw-nix.yaml
    ```

    If the user asks to commit/push, first verify staged content:

    ```bash
    git status --short
    git diff --cached --stat
    git diff --cached
    ```

    Then commit only the intended source and generated manifest changes.

    ### Deploy and verify

    ```bash
    # Force Flux to reconcile only after commit+push
    kubectl annotate -n flux-system gitrepository/flux-system reconcile.fluxcd.io/requestedAt="$(date -Iseconds)" --overwrite

    # Watch pod status
    kubectl get pod -n apps -l app.kubernetes.io/name=openclaw-nix -w
    ```

    **Success criteria** (see `references/checks.md` for detailed verification):
    - Pod shows `Running` with `READY` column eventually reaching `2/2`
    - Health check: `kubectl exec ... -- /bin/curl -m 15 -sS http://127.0.0.1:18789/health` returns `{"ok":true,"status":"live"}`
    - Logs contain `[gateway] ready` with plugin list
    - No `ImagePullBackOff` or `ErrImagePull` events

    Large image pulls can exceed deployment progress deadlines. Do not treat
    `ProgressDeadlineExceeded` as failure while events still show `Pulling`; wait for `Pulled`, then
    verify readiness, logs, and `/health`.

    ### Matrix routing smoke check

    If Matrix agents are enabled, verify routing state after upgrade:

    ```bash
    kubectl exec -n apps deploy/openclaw-nix -c main -- openclaw sessions --agent mel --active 120 --json
    ```

    For DM failures, compare session kind with a working agent:
    - Good DM: `matrix:<account>:direct:@user`
    - Suspicious: `matrix:channel:<room-id>`

    If an agent sends only 👀 reactions but no text, inspect Matrix room history for `m.reaction`
    vs `m.room.message` and check the bot's `m.direct` account data contains the current room ID.

    ### Remediation for common failures

    | Symptom | Cause | Fix |
    |---------|-------|-----|
    | `not found` pulling image | Remote digest ≠ local digest | Phase 4 step 5 — repush and get correct remote digest |
    | `Multi-Attach error` | RWO PVCs locked to old node | Delete `VolumeAttachment` resources, wait 30-60s for Ceph cleanup |
    | `ErrImagePull` + BackOff | Image never reached GHCR | Phase 4 — verify with `podman pull ghcr.io/...` then re-push |
    | Pod stuck `ContainerCreating` | Large image pull in progress | Wait up to 15 min for 2.3GB image; check events for `Pulling` → `Pulled` |
    | Pod stays `1/2 Running` | Readiness probe hasn't passed yet | Wait for `[gateway] ready` in logs; check `/health` endpoint |
    | Flux apply says probe has multiple handlers | SSA retained old probe handler | Patch/remove old live handler or recreate after confirming desired manifest |
    | Pod stuck `Terminating` during rollout | Large image pull or stale sandbox | Force-delete pod only if replacement is blocked; inspect events and node sandbox errors |
    | Gateway stalls after channel startup | CephFS credential/runtime-dep lock | Check `/proc/1/fd` for Matrix credential `*.tmp`; keep plugin stage dir pod-local |
    | `openclaw: not found` in container | Image `/bin` refactor dropped app binary | Re-run local smoke test: `which openclaw` before pushing |

    ## See Also

    - `references/checks.md` — detailed post-deploy verification checklist
    - `/home/josevictor/Workspace/homelab/.docs/rules.md` — project gotchas (digest mismatch, RBD locks)
    - `/home/josevictor/Workspace/homelab/AGENTS.md` — homelab knowledge base
  '';
}
