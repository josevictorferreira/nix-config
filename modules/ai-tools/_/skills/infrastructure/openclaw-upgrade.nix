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
  name = "openclaw-upgrade";
  description = ''
    Complete workflow for upgrading the openclaw debian-based container image version in the homelab.
    Use when asked to upgrade, bump, or update the openclaw debian image, OpenClaw version, or
    openclaw container. Triggers on: "upgrade openclaw", "update openclaw debian image",
    "bump openclaw version", "new openclaw release", "openclaw v{version}".
  '';
  references = {
    "checks" = ''
      # OpenClaw Post-Deploy Verification

      Run these checks after the pod is `Running`. Each check must pass before considering the upgrade successful.

      ## 1. Pod Status

      ```bash
      kubectl get pod -n apps -l app.kubernetes.io/name=openclaw -o wide
      ```

      **Expected:** `READY` column shows `2/2`, `STATUS` is `Running`, zero `RESTARTS`.
      If `1/2`: wait — the readiness probe is still evaluating. Check logs.
      If `0/2` + `ImagePullBackOff`: see `references/troubleshooting.md`.

      ## 2. Image Digest

      ```bash
      kubectl get pod -n apps -l app.kubernetes.io/name=openclaw -o jsonpath='{.items[0].status.containerStatuses[?(@.name=="main")].imageID}' | cut -d'@' -f2
      ```

      **Expected:** Matches the pinned digest in `modules/kubenix/apps/openclaw.nix`.
      Compare with: `grep 'tag =' modules/kubenix/apps/openclaw.nix`

      ## 3. Health Endpoint

      ```bash
      kubectl exec -n apps deploy/openclaw -c main -- /bin/curl -m 15 -sS http://127.0.0.1:18789/health
      ```

      **Expected:** `{"ok":true,"status":"live"}`

      ## 4. Gateway Readiness

      ```bash
      kubectl logs -n apps deploy/openclaw -c main --tail=50 | grep -E 'gateway.*ready|http server listening'
      ```

      **Expected:** Contains `[gateway] http server listening` with plugin list and `[gateway] ready`.
      Shows plugins like: `lossless-claw, matrix, memory-lancedb, memory-wiki, whatsapp`.

      ## 5. No Crash Loops

      ```bash
      kubectl get pod -n apps -l app.kubernetes.io/name=openclaw -o jsonpath='{.items[0].status.containerStatuses[?(@.name=="main")].restartCount}'
      ```

      **Expected:** `0` (or low number if just deployed). If > 2 in first 5 minutes, check logs for errors.

      ## 6. Event Audit

      ```bash
      kubectl describe pod -n apps -l app.kubernetes.io/name=openclaw | grep -E 'Pulling|Pulled|Failed|BackOff|Mount'
      ```

      **Expected:**
      - `Normal Pulling` → `Normal Pulled` for both `chromium` and `main` containers
      - No `Failed`, no `BackOff`, no `FailedMount`, no `Multi-Attach`

      ## 7. Matrix Connectivity (if Matrix plugin enabled)

      ```bash
      kubectl logs -n apps deploy/openclaw -c main --tail=100 | grep -E '\[matrix\].*started|\[matrix\].*sync'
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
    # OpenClaw Image Upgrade

    Complete step-by-step flow for upgrading the `openclaw` OCI container image and deploying
    it to the homelab Kubernetes cluster.

    ## Overview

    There are TWO OpenClaw image types in this repo:
    - **nix-based** (`openclaw`): Built via podman from `oci-images/openclaw/Dockerfile`. Heavy (~7GB).
    - **debian-based** (`openclaw-debian`): Built via Nix from `oci-images/openclaw-debian.nix`
      using `dockerTools.pullImage` for the base + tools overlay (~550MB).

    This upgrade involves 5 phases:
    1. **Verify upstream** — confirm the target version tag exists
    2. **Update Nix sources** — bump version strings across the tag chain
    3. **Build image** — Nix build (debian) or podman build (nix)
    4. **Push to GHCR** — push image, verify remote digest, pin in manifest
    5. **Deploy** — regenerate manifests, config migration check, apply, verify pod

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
    - The openclaw pod may include sidecars (for example `chromium`) in addition to `main`.
      Always pass `-c main` for `/health`, logs, and CLI invocations.
    - **Debian image**: The `openclaw-debian.nix` build requires `NIXPKGS_ALLOW_UNFREE=1` (obsidian
      has unfree license). The `make push-openclaw-debian` command does NOT pass `--impure` — push
      manually if needed.

    ## Phase 1: Verify Upstream

    ```bash
    # Confirm the upstream release tag exists
    git ls-remote --tags https://github.com/openclaw/openclaw "refs/tags/v{VERSION}"
    ```

    If the tag doesn't exist, the build will fail at fetch time with 404.

    ## Phase 2: Update Sources

    **Files to edit (trace the full tag chain first):**

    ```bash
    grep -rn 'imageTag\|openclawVersion\|tagSuffix\|image.tag\|tag =' flake.nix oci-images/ modules/
    ```

    ### For the nix-based image (`openclaw`)

    - `oci-images/openclaw/Dockerfile` — update base image or build args
    - `modules/commands.nix` line ~558: `openclawVersion = "{VERSION}";`

    ### For the debian-based image (`openclaw-debian`)

    - `oci-images/openclaw-debian.nix` — update the `tag` in `dockerTools.pullImage` at line ~111
      to point to the upstream `ghcr.io/openclaw/openclaw:{VERSION}`. If the base image version
      changes, the `pullImage` FOD hash will mismatch — run `nix build` to get the new hash.
      The tools overlay (ffmpeg, obsidian, typst, etc.) and lossless-claw plugin overlay stay the same.
    - `modules/commands.nix` line ~561: `openclawDebianVersion = "{VERSION}";`
    - `modules/kubenix/apps/openclaw.nix` line ~8: Update the `image` tag string and digest.

    ## Phase 3: Build Image

    ### For the nix-based image:
    ```bash
    podman build -t localhost/openclaw:v{VERSION} -f oci-images/openclaw/Dockerfile oci-images/openclaw/
    ```

    ### For the debian-based image:
    ```bash
    NIXPKGS_ALLOW_UNFREE=1 nix build .#openclaw-debian-image
    ```

    This must succeed. For the debian image, a `dockerTools.pullImage` FOD hash mismatch
    is expected — copy the new hash from the error message into `oci-images/openclaw-debian.nix`.

    ### Local image smoke tests

    Before pushing, validate the built image. Always confirm the main binary and basic
    runtime tools exist:

    ```bash
    LOCAL_TAG=$(podman images localhost/openclaw --format '{{.Tag}}' | grep '^v{VERSION}' | head -1)
    podman run --rm --entrypoint "" localhost/openclaw:"$LOCAL_TAG" sh -c 'OPENCLAW_ALLOW_ROOT=1 openclaw --version && which openclaw && which sed && which cat && which ls'
    ```

    ## Phase 4: Push to GHCR

    ### Run push command
    ```bash
    make push-openclaw
    ```

    **If `make push-openclaw` times out** during the auto-pin step (step 6/6), complete manually:

    ```bash
    # 1. Derive the loaded local tag; do not hardcode tag suffixes
    LOCAL_TAG=$(podman images localhost/openclaw --format '{{.Tag}}' | grep '^v{VERSION}' | head -1)
    test -n "$LOCAL_TAG"

    # 2. Remove stale local GHCR tags to prevent collisions
    podman rmi -f ghcr.io/josevictorferreira/openclaw:latest \
      ghcr.io/josevictorferreira/openclaw:"$LOCAL_TAG" 2>/dev/null || true

    # 3. Log in
    echo "$(gh auth token)" | podman login ghcr.io -u josevictorferreira --password-stdin

    # 4. Tag and push
    podman tag localhost/openclaw:"$LOCAL_TAG" ghcr.io/josevictorferreira/openclaw:latest
    podman tag localhost/openclaw:"$LOCAL_TAG" ghcr.io/josevictorferreira/openclaw:"$LOCAL_TAG"
    # 4. Push (background — image is ~7GB, foreground pushes routinely exceed 10-min tool timeouts).
    mkdir -p /tmp/opencode
    nohup podman push --format=oci ghcr.io/josevictorferreira/openclaw:"$LOCAL_TAG" \
      > /tmp/opencode/push-openclaw.log 2>&1 &
    PUSH_PID=$!
    while kill -0 $PUSH_PID 2>/dev/null; do sleep 60; tail -1 /tmp/opencode/push-openclaw.log; done
    tail -3 /tmp/opencode/push-openclaw.log  # expect "Writing manifest to image destination"

    nohup podman push --format=oci ghcr.io/josevictorferreira/openclaw:latest \
      > /tmp/opencode/push-latest.log 2>&1 &
    wait

    # 5. Get the REMOTE digest (NOT local!)
    REMOTE_DIGEST=$(skopeo inspect --format \'{{.Digest}}\' docker://ghcr.io/josevictorferreira/openclaw:"$LOCAL_TAG")
    ```

    ### Pin digest in manifest

    ```nix
    # modules/kubenix/apps/openclaw.nix line ~8:
    tag = "<LOCAL_TAG>@<REMOTE_DIGEST>";
    ```

    CRITICAL: Use the REMOTE digest from `skopeo inspect`, NOT the local digest. The local
    digest from `streamLayeredImage` can differ from what the registry computes.

    If `skopeo` is unavailable, pull the pushed image and read the digest after that pull:
    ```bash
    podman pull ghcr.io/josevictorferreira/openclaw:"$LOCAL_TAG"
    podman images --digests --format '{{.Repository}}:{{.Tag}} {{.Digest}} {{.ID}}' \
      | grep "ghcr.io/josevictorferreira/openclaw:$LOCAL_TAG"
    ```

    ## Phase 5: Deploy

    ### Regenerate manifests
    ```bash
    make manifests
    ```

    Verify the generated `.k8s/apps/openclaw.yaml` contains the correct digest (should match
    the remote digest hash you confirmed above).

    If the container runs as root (`runAsUser = 0`) and OpenClaw exits with
    `[openclaw] Refusing to run as root`, add this explicit container opt-in:
    ```nix
    OPENCLAW_ALLOW_ROOT = "1";
    ```

    Only run the full pipeline. Do not run individual manifest stages (`nix build .#gen-manifests`,
    `vals eval`, etc.) because they can leave `.k8s/` misleading or incomplete.

    If new secret keys or encrypted config keys were added, remove the affected file's stale entry
    from `manifests.lock` and delete that generated `.k8s/...` file before `make manifests`; the
    unlock/restore stage can otherwise restore the old encrypted file.

    ### Validate live OpenClaw config safely

    **The canonical OpenClaw config is `~/Homelab/openclaw/openclaw.json` on CephFS.** This is the PRIMARY
    configuration. The Nix source at `modules/kubenix/apps/openclaw-config.enc.nix` is a MIRROR of it,
    and the Kubernetes configmap is fallback only.

    Do not dump the full config. Use allowlisted structural checks only:

    ```bash
    jq '.channels.matrix.groups | keys' ~/Homelab/openclaw/openclaw.json
    jq '.plugins.slots, (.plugins.entries | keys)' ~/Homelab/openclaw/openclaw.json
    ```

    When config keys need to be added, removed, or changed, **always edit the live CephFS config first**
    (`~/Homelab/openclaw/openclaw.json`), then mirror the non-secret structural changes to the Nix
    source (`modules/kubenix/apps/openclaw-config.enc.nix`). Never edit the Nix source alone —
    the CephFS mount controls what the running pod actually reads.

    ### Check config key migration

    Before deploying, check if the new OpenClaw version removed or renamed config keys:

    ```bash
    # Run doctor against the local image to catch config issues early
    podman run --rm --entrypoint "" ghcr.io/josevictorferreira/openclaw-debian:{VERSION} \
      sh -c 'OPENCLAW_ALLOW_ROOT=1 openclaw doctor 2>&1' 2>/dev/null || true
    ```

    Common keys removed in recent versions:
    - v2026.5.18: `silentReply`, `silentReplyRewrite`

    If the gateway fails to start with `Invalid config`, check pod logs and **patch the real CephFS
    config first** (`~/Homelab/openclaw/openclaw.json`), then mirror the non-secret changes to the Nix
    source (`modules/kubenix/apps/openclaw-config.enc.nix`).

    ### Persist or apply changes

    Do not commit unless the user explicitly asks.

    Flux reconciles from git, not local `.k8s/` output. If changes are not committed and pushed,
    `flux reconcile` will not deploy them.

    If the user wants immediate deployment from uncommitted local changes, apply the generated
    manifest directly:

    ```bash
    kubectl config current-context  # must be ze-homelab
    kubectl apply -f .k8s/apps/openclaw.yaml
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
    kubectl get pod -n apps -l app.kubernetes.io/name=openclaw -w
    ```

    **Success criteria** (see `references/checks.md` for detailed verification):
    - Pod shows `Running` with `READY` column eventually reaching `2/2`
    - Health check: `kubectl exec ... -- /bin/curl -m 15 -sS http://127.0.0.1:18789/health` returns `{"ok":true,"status":"live"}`
    - Logs contain `[gateway] ready` with plugin list
    - No `ImagePullBackOff` or `ErrImagePull` events

    ### Plugin load verification

    After the pod reaches `Running`, check for plugin/channel load failures. `/health` returning `{"ok":true}` does NOT confirm
    that all plugins loaded successfully.

    ```bash
    kubectl logs -n apps deploy/openclaw -c main --tail=50 | grep -E 'failed to load|not registered|escapes plugin root'
    ```

    **Expected:** No matches. If `[channels] failed to load bundled channel` appears, see the bundled plugin resolver note above.

    Large image pulls can exceed deployment progress deadlines. Do not treat
    `ProgressDeadlineExceeded` as failure while events still show `Pulling`; wait for `Pulled`, then
    verify readiness, logs, and `/health`.

    ### Adding external (non-bundled) plugins at runtime

    For plugins not bundled in the OCI image (e.g., `@vectorize-io/hindsight-openclaw`), install at
    runtime in the container entrypoint:

    ```bash
    # In entrypoint, before exec node:
    npm install -g @vectorize-io/hindsight-openclaw
    cp -r /data/npm-global/lib/node_modules/@vectorize-io/hindsight-openclaw \
      /data/openclaw/extensions/hindsight-openclaw
    ```

    **Critical path details:**

    1. **Global extensions dir** is `$OPENCLAW_STATE_DIR/extensions/` (currently `/data/openclaw/extensions/`),
       NOT `$HOME/.openclaw/extensions/`. Verify with `env | grep OPENCLAW_STATE_DIR`.
    2. **Memory plugin slot**: OpenClaw allows only ONE `kind: "memory"` plugin. Set
       `plugins.slots.memory` in config to the desired memory plugin. Others are silently disabled.
    3. **Conversation hooks**: Non-bundled plugins with conversation-level hooks need
       `plugins.entries.<id>.hooks.allowConversationAccess = true` in config.
    4. **Stock vs global**: Copying to `/lib/openclaw/dist/extensions/` (stock) causes "duplicate plugin id"
       warning; prefer the global path to avoid bundled override.


    ### Matrix routing smoke check

    If Matrix agents are enabled, verify routing state after upgrade:

    ```bash
    kubectl exec -n apps deploy/openclaw -c main -- openclaw sessions --agent mel --active 120 --json
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
    | `Invalid config` on startup | New version removed/renamed config keys | Check pod logs for `Invalid config`; patch live CephFS config and Nix source (`openclaw-config.enc.nix`); run `openclaw doctor --fix` |

    ## See Also

    - `references/checks.md` — detailed post-deploy verification checklist
    - `/home/josevictor/Workspace/homelab/.docs/rules.md` — project gotchas (digest mismatch, RBD locks)
    - `/home/josevictor/Workspace/homelab/AGENTS.md` — homelab knowledge base
  '';
}
