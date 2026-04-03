# jvf.home materialization + wrappers split (incremental)

## TL;DR
> **Summary**: Split `modules/wrappers.nix` into (A) wrapper/script install + packages, (B) new `jvf.home` subsystem that owns all home file/dir materialization. Preserve behavior via compat translation (wrappers → home) and migrate only 3 reps (kitty/waybar/claudecode).
> **Deliverables**:
> - New aspect: `self.modules.{nixos,darwin}.home` implementing `jvf.home.*`
> - `wrappers.nix` no longer materializes configs; generates `jvf.home` specs for legacy `configs/configPath/preserveFiles/postInstall`
> - New flake checks: eval + NixOS VM integration for home materialization
> - Migrate: `programs/kitty`, `desktop/hyprland/waybar`, `programs/claudecode`
> **Effort**: Large
> **Parallel**: YES — 3 waves
> **Critical Path**: home schema+activation → wrappers compat translation → checks/vm → migrate 3 modules

## Context
### Original Request
- Incremental refactor (no rewrite) of module structure around `wrappers` + “base” modules installing programs + deploying user configs.
- Improve API ergonomics for managing `~/.config` + other home-relative paths.
- Rank changes by necessity.
- Add unit+integration tests for complex “base” modules.
- First deliverable: complete plan for the whole refactor.

### Repo Grounding (key facts)
- `modules/wrappers.nix` (476 LOC) currently combines:
  1) wrapper env/bin generation + `~/.local/bin` linking
  2) config materialization into `$HOME/.config/<program>` or custom `configPath` with atomic swap + preserve + `postInstall`
  - hardcodes home path as `/home/<user>` or `/Users/<user>`
  - NixOS: per-user `system.activationScripts."jvf-wrappers-${user}"` (`supportsDryActivation = true`)
  - Darwin: `system.activationScripts.postActivation`
- Consumers: `jvf.wrappers.users.*.programs.*` referenced ~33 times across `modules/programs/*` and `modules/desktop/hyprland/*`.
  - “complex features” concentrated in: `programs/claudecode`, `programs/opencode`, `desktop/hyprland/waybar`.
- `modules/repositories.nix` and `modules/system/xdg.nix` also write into home; **OUT OF SCOPE** for this refactor.
- Checks currently: only `checks.statix` in `modules/overlays.nix`; no nixosTest infra yet.

### Decisions (locked for executor)
1) **`jvf.home` complements + absorbs file materialization; wrappers keeps wrappers.**
   - `jvf.wrappers` remains the wrapper/script + package surface.
   - ALL file/dir materialization + `preserveFiles` + `postInstall` moves to `jvf.home`.
2) **Backward compat via translation layer in `wrappers.nix` (no user-facing breakage).**
   - Existing modules not migrated keep working: they set `jvf.wrappers...configs` and wrappers compiles that into `jvf.home` specs.
3) **No backend swap**: keep activation-script approach; do NOT switch to tmpfiles.d (future work).
4) **Migration scope**: only 3 reps in this work: `kitty` (simple), `waybar` (postInstall), `claudecode` (preserve + custom path + postInstall).
5) **Test scope**: add Nix eval checks + NixOS VM integration tests; Darwin gets eval probes (no VM).
6) **Safety**: cleanup is conservative. No deletion beyond what current wrappers already does for legacy path; new `jvf.home` default semantics avoid unsafe global cleanup.

### Necessity ranking (why ordered this way)
1) Necessary: `jvf.home` schema + activation + conflict detection (enables rest).
2) Necessary: wrappers compat translation + stop hardcoded `/home`/`/Users`.
3) Necessary: checks + VM test (prevents regressions; enforces behavior).
4) High value: migrate 3 reps (proves API + covers edge cases).
5) Optional follow-ups (explicitly NOT in this plan): migrate `repositories.nix`, migrate `system/xdg.nix`, switch to tmpfiles.d, migrate remaining 29 modules.

### Metis Review (gaps addressed)
- Clarified boundary: wrappers keeps launcher generation; `jvf.home` owns materialization.
- Added: compat bridge + conflict detection + strict scope guardrails.
- Added: VM test that covers content + postInstall + preserve (2-system switch).

## Work Objectives
### Core Objective
Deliver `jvf.home` ergonomic API + robust materialization backend, while preserving existing behavior through a wrappers→home compat layer.

### Deliverables
- New aspect module(s): `modules/home/default.nix` exporting:
  - `flake.modules.nixos.home`
  - `flake.modules.darwin.home`
- Updated `modules/wrappers.nix`:
  - config materialization removed
  - generates `jvf.home.users.<user>.items` from legacy `jvf.wrappers.users.<user>.programs.<program>`
  - wrapper/script linking stays
  - home path derived from `config.users.users.<user>.home` when present
- New checks (flake-parts `perSystem.checks.*`):
  - `jvf-home-eval` (pure eval guard)
  - `jvf-home-vm` (NixOS integration test)
- Migrations:
  - `modules/programs/kitty/default.nix`
  - `modules/desktop/hyprland/waybar.nix`
  - `modules/programs/claudecode/default.nix`

### Definition of Done (agent-verifiable)
- `make check` passes.
- `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.home --show-trace` succeeds.
- `nix eval .#darwinConfigurations.macos-macbook.config.jvf.home --show-trace` succeeds (on Linux).
- `nix build .#checks.x86_64-linux.jvf-home-eval --show-trace` succeeds.
- `nix build .#checks.x86_64-linux.jvf-home-vm --show-trace` succeeds.
- Legacy modules still using wrappers configs continue to evaluate (no option removals) and do not duplicate materialization.

### Must NOT Have (guardrails)
- No Home Manager.
- No migration of `modules/repositories.nix` or `modules/system/xdg.nix`.
- No switch from activation scripts to tmpfiles.*.
- No mass migration of all wrappers consumers.
- No new secret-handling mechanism (no sops integration here).

## Verification Strategy
> ZERO HUMAN INTERVENTION — all verification agent-executed.
- Tests: add flake checks for eval + NixOS VM.
- QA policy: every task below includes a runnable scenario + evidence output file.
- Evidence: `.sisyphus/evidence/task-{N}-{slug}.txt` (or `.log`).

## Execution Strategy
### Parallel Execution Waves
Wave 1 (foundation): home schema+activation + checks scaffolding

Wave 2 (refactor): wrappers split + compat translation

Wave 3 (adoption): migrate kitty → waybar → claudecode + expand VM test assertions

### Dependency Matrix (summary)
- T1 blocks: T2–T8
- T2 blocks: T6–T8
- T3 blocks: T5–T8
- T4 blocks: T5–T8
- T5 blocks: T6–T8
- T6 blocks: T7–T8
- T7 blocks: T8

## TODOs

- [x] 1. Add new `home` aspect skeleton + option schema (`jvf.home.*`)

  **What to do**:
  - Create `modules/home/default.nix` exporting both platforms via `mkConfig { isDarwin }` (match pattern in `modules/wrappers.nix`).
  - Define canonical multi-user namespace:
    - `jvf.home.users.<user>.items."<relTarget>" = itemSpec` (attrsOf submodule)
  - Define default-user sugar (maps to `config.jvf.core.username`):
    - `jvf.home.files."<rel>" = itemSpec`
    - `jvf.home.xdg.{config,data,state,cache}."<rel>" = itemSpec`
    - Implementation MUST compile sugar into `jvf.home.users.<defaultUser>.items`.
  - Define `itemSpec` (decision locked):
    - `kind = "file"|"dir"` (required)
    - `mode = "copy"|"link"|"seed"` (default `copy`)
    - exactly one content source:
      - `source = path|derivation|storePathString` (for file or dir)
      - OR `text = lines` (file)
      - OR `json|yaml|toml|ini = attrs` (file; serializer explicit)
    - `preserve = [ "rel/path" ... ]` (dir only; default `[]`)
    - `postInstall = lines` (default "")
  - Implement compile-time validation:
    - Reject overlapping targets (one path prefix of another) within a user.
    - Reject invalid `preserve` when `kind != dir`.
    - Reject missing content source.
  - Implement `_compiled` output for debugging/tests:
    - `config.jvf.home._compiled.users.<user>.items :: list { targetAbs, targetRel, kind, mode, sourcePath, preserve, postInstall }`.

  **Must NOT do**:
  - Do not apply any activation writes yet (T2).
  - Do not touch wrappers/repositories/xdg.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` — new option API + types.
  - Skills: [`writing-nix-code`] — ensure idiomatic types + mkOption.

  **Parallelization**: Can Parallel: NO | Wave 1 | Blocks: T2–T8 | Blocked By: none

  **References**:
  - Pattern: `modules/wrappers.nix:7-95` — mkOption + mkConfig {isDarwin} dual export.
  - Pattern: `modules/flake/default.nix` — flake.modules mergeable option.
  - Consumer target: `.claude` via `modules/programs/claudecode/default.nix:209-273` (needs non-XDG path).

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.home --show-trace` succeeds.
  - [ ] `nix eval .#darwinConfigurations.macos-macbook.config.jvf.home --show-trace` succeeds.
  - [ ] Evidence: `.sisyphus/evidence/task-1-home-schema.txt` contains both eval command outputs (or “success”).

  **QA Scenarios**:
  ```
  Scenario: Option tree exists on both platforms
    Tool: Bash
    Steps:
      1) nix eval .#nixosConfigurations.nixos-desktop.config.jvf.home --show-trace
      2) nix eval .#darwinConfigurations.macos-macbook.config.jvf.home --show-trace
    Expected: both succeed
    Evidence: .sisyphus/evidence/task-1-home-schema.txt
  ```

  **Commit**: YES | Message: `refactor(home): add jvf.home option schema scaffold` | Files: `modules/home/default.nix`


- [x] 2. Implement `jvf.home` activation (materialize file/dir + preserve + postInstall)

  **What to do**:
  - In `modules/home/default.nix`, implement per-user activation scripts:
    - NixOS: `system.activationScripts."jvf-home-${user}" = { supportsDryActivation = true; text = ...; };`
    - Darwin: append to `system.activationScripts.postActivation.text` (per user loop like wrappers).
  - Home path + group resolution (decision locked):
    - `home = config.users.users.${user}.home or (if isDarwin then "/Users/${user}" else "/home/${user}")`
    - `group = config.users.users.${user}.group or (if isDarwin then "staff" else "users")`
  - Apply semantics (decision locked):
    - `mode=seed`:
      - file: if target missing → install (copy) else no-op
      - dir: if dir missing → create and copy initial tree else no-op
    - `mode=copy`:
      - file: atomic replace (write to `target.tmp`, then `mv -f`)
      - dir: wrappers-style atomic swap:
        - stage to `${TARGET_PATH}.tmp`, compare `diff -r -q`, if unchanged → clean tmp, skip
        - if changed: move existing to backup dir, replace, restore `preserve` from backup if present
    - `mode=link`:
      - file/dir: `ln -sfn <storeSource> <target>` (ensure parent dirs)
      - preserve ignored for link (warn at eval time).
  - Ownership/perms (match wrappers behavior):
    - `chown -R user:group` after copy/seed of dirs; file `chown user:group`.
    - perms: dirs 755, files 644.
  - `postInstall` execution contract (decision locked): run after successful apply (including unchanged? NO — only when changed or created).
    - Provide env vars:
      - `USER_NAME`, `GROUP_NAME`, `HOME_DIR`
      - `TARGET_PATH` (absolute), `BACKUP_DIR` ("" if none)
      - `IS_DARWIN=1|0`
  - Logging: prefix each item with `echo "[jvf.home] ..."`.

  **Must NOT do**:
  - No global cleanup of unmanaged paths.
  - No tmpfiles backend.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` — bash-in-Nix activation + cross-platform.
  - Skills: [`writing-nix-code`] — correct quoting, safe bash.
  - Omitted: [`developing-containers`] — irrelevant.

  **Parallelization**: Can Parallel: NO | Wave 1 | Blocks: T3–T8 | Blocked By: T1

  **References**:
  - Pattern: wrappers atomic swap + preserve + postInstall: `modules/wrappers.nix:325-395`.
  - Group/home fallback style: `modules/repositories.nix:46-49`.
  - Current postInstall contract uses `$TARGET_PATH`: `modules/desktop/hyprland/waybar.nix:100-105`.

  **Acceptance Criteria**:
  - [ ] `make check` passes.
  - [ ] `nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel --no-link` succeeds.
  - [ ] Evidence: `.sisyphus/evidence/task-2-home-activation.txt` contains outputs.

  **QA Scenarios**:
  ```
  Scenario: System builds with new activation scripts
    Tool: Bash
    Steps:
      1) make check
      2) nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel --no-link
    Expected: both succeed
    Evidence: .sisyphus/evidence/task-2-home-activation.txt
  ```

  **Commit**: YES | Message: `feat(home): materialize home files via activation scripts` | Files: `modules/home/default.nix`


- [x] 3. Add flake checks: eval guard + NixOS VM integration test for `jvf.home`

  **What to do**:
  - Add new flake-parts module: `modules/checks/home.nix` (any path under `modules/` is fine; MUST export `perSystem` only).
  - Add `perSystem.checks.jvf-home-eval`:
    - Pure Nix evaluation of a minimal NixOS module stack containing: `core-jvf`, `core-theme`, `users`, `home`, `wrappers`.
    - Use `lib.evalModules`-style evaluation via nixpkgs lib (do NOT shell out to `nix` inside derivation).
    - Assert: `config.jvf.home._compiled.users` exists and is an attrset.
  - Add `perSystem.checks.jvf-home-vm` using `pkgs.nixosTest`:
    - Build **two** NixOS toplevels (A and B) in the test expression; switch from A→B in testScript to force a config change.
    - Node A config:
      - create user `alice` with passwordless root (default in tests) + home `/home/alice`.
      - enable `jvf.home` items:
        - `.config/kitty/kitty.conf` (text contains sentinel `font_size 13`)
        - `.config/waybar` dir from a tiny generated source dir (NOT repo assets) to keep test small
        - `.claude` dir with `settings.json` content **A**; `preserve=["transcripts","history.jsonl"]`; postInstall writes `~/.claude.json` from `settings.json` using `jq`.
    - Node B config: same but `settings.json` content **B** (forces diff+swap).
    - TestScript assertions (binary):
      - After boot A: kitty file exists + contains sentinel.
      - After boot A: waybar dir exists.
      - Create preserved file(s): `/home/alice/.claude/transcripts/keep.txt` and `/home/alice/.claude/history.jsonl`.
      - Switch to toplevel B using `${toplevelB}/bin/switch-to-configuration test`.
      - Assert preserved files still exist after switch.
      - Assert `.claude/settings.json` now matches B and `.claude.json` updated.

  **Must NOT do**:
  - Don’t depend on host configs (`nixos-desktop`); test must be self-contained.
  - Don’t depend on repo assets tree (keep nixosTest closure small).

  **Recommended Agent Profile**:
  - Category: `unspecified-high` — NixOS VM test authoring.
  - Skills: [`writing-nix-code`] — nixosTest patterns.

  **Parallelization**: Can Parallel: YES | Wave 1 | Blocks: T5–T8 | Blocked By: T2

  **References**:
  - Existing checks pattern: `modules/overlays.nix:24-36` (`perSystem.checks.*`).
  - Need `jq` in postInstall example: see `modules/programs/claudecode/default.nix:240-252`.

  **Acceptance Criteria**:
  - [ ] `nix build .#checks.x86_64-linux.jvf-home-eval --show-trace` succeeds.
  - [ ] `nix build .#checks.x86_64-linux.jvf-home-vm --show-trace` succeeds.
  - [ ] Evidence: `.sisyphus/evidence/task-3-home-checks.txt` includes both build outputs.

  **QA Scenarios**:
  ```
  Scenario: VM test validates copy+preserve+postInstall
    Tool: Bash
    Steps:
      1) nix build .#checks.x86_64-linux.jvf-home-vm --show-trace
    Expected: build succeeds; test assertions pass
    Evidence: .sisyphus/evidence/task-3-home-checks.txt
  ```

  **Commit**: YES | Message: `test(home): add eval + nixosTest checks` | Files: `modules/checks/home.nix`


- [x] 4. Split `wrappers.nix`: remove config materialization; translate legacy configs into `jvf.home`

  **What to do**:
  - In `modules/wrappers.nix`:
    - Keep option schema unchanged (backward compat).
    - Change runtime behavior:
      - Wrapper install (`~/.local/bin` symlink) remains.
      - Packages-only behavior remains (`command == null || ""` → per-user packages).
      - Config materialization logic removed from wrappers activation script.
    - Add translation layer (decision locked):
      - For each `jvf.wrappers.users.<u>.programs.<p>` with `configs != { }` and `useDerivationConfig == false`:
        - Generate one `jvf.home.users.<u>.items."<configPathOrDefault>"` item:
          - `kind = "dir"`
          - `mode = "copy"`
          - `source = <existing wrappers configDir>` (reuse current `processConfigs` + `pkgs.linkFarm` output)
          - `preserve = preserveFiles`
          - `postInstall = postInstall` (as-is)
      - Target rel path is `${configPath or ".config/${programName}"}`.
    - Ensure wrappers module imports the home module automatically (to avoid host edits):
      - Update flake-parts signature to `{ self, ... }:`
      - Set `imports = [ mkWrappersOption self.modules.nixos.home ]` (and darwin analog).
  - Fix hardcoded home paths:
    - Use `config.users.users.${user}.home` when present; fallback to `/home` or `/Users`.
  - Conflict policy (decision locked):
    - If both legacy wrappers translation AND direct `jvf.home.users.<u>.items` target the same rel path → evaluation error with explicit message.

  **Must NOT do**:
  - Don’t change wrappers public option names/types.
  - Don’t migrate consumers here.

  **Recommended Agent Profile**:
  - Category: `unspecified-high` — refactor + compat bridge.
  - Skills: [`writing-nix-code`] — safe refactor.

  **Parallelization**: Can Parallel: NO | Wave 2 | Blocks: T5–T8 | Blocked By: T2

  **References**:
  - wrappers config materialization block to remove: `modules/wrappers.nix:325-395`.
  - wrappers wrapper install block to keep: `modules/wrappers.nix:315-323`.
  - Users home/group lookup pattern: `modules/repositories.nix:46-49`.

  **Acceptance Criteria**:
  - [ ] `make check` passes.
  - [ ] `nix build .#checks.x86_64-linux.jvf-home-vm --show-trace` still passes.
  - [ ] Evidence: `.sisyphus/evidence/task-4-wrappers-split.txt` contains outputs.

  **QA Scenarios**:
  ```
  Scenario: Legacy wrappers consumers still materialize via translation
    Tool: Bash
    Steps:
      1) nix build .#checks.x86_64-linux.jvf-home-vm --show-trace
      2) nix eval .#nixosConfigurations.nixos-desktop.config.jvf.wrappers.users.josevictor.programs.kitty.configs --show-trace
    Expected: VM test passes; eval succeeds (compat options intact)
    Evidence: .sisyphus/evidence/task-4-wrappers-split.txt
  ```

  **Commit**: YES | Message: `refactor(wrappers): delegate config materialization to jvf.home` | Files: `modules/wrappers.nix`


- [x] 5. Migrate `programs/kitty` to `jvf.home` (simple tier)

  **What to do**:
  - In `modules/programs/kitty/default.nix`:
    - Keep package installation via wrappers (or users packages) as-is.
    - Move config write from wrappers to home:
      - Replace:
        - `jvf.wrappers.users.${cfg.username}.programs.kitty.configs."kitty.conf" = ...`
      - With:
        - `jvf.home.users.${cfg.username}.xdg.config."kitty/kitty.conf" = { kind = "file"; mode = "copy"; text = ...; };`
  - Ensure no duplicated target (wrappers translation should no longer generate kitty dir spec).

  **Must NOT do**:
  - Don’t refactor kitty settings generation.

  **Recommended Agent Profile**:
  - Category: `quick` — single consumer migration.
  - Skills: [`writing-nix-code`] — consistent option usage.

  **Parallelization**: Can Parallel: YES | Wave 3 | Blocks: T6–T8 | Blocked By: T4

  **References**:
  - Current kitty wrappers config: `modules/programs/kitty/default.nix:145-152`.
  - New target API: `modules/home/default.nix` (`jvf.home.users.*.xdg.config.*`).

  **Acceptance Criteria**:
  - [ ] `make check` passes.
  - [ ] `nix build .#checks.x86_64-linux.jvf-home-vm --show-trace` passes.
  - [ ] Evidence: `.sisyphus/evidence/task-5-kitty-migrate.txt`.

  **QA Scenarios**:
  ```
  Scenario: Kitty config materializes via jvf.home
    Tool: Bash
    Steps:
      1) nix build .#checks.x86_64-linux.jvf-home-vm --show-trace
    Expected: VM test includes kitty assertion and passes
    Evidence: .sisyphus/evidence/task-5-kitty-migrate.txt
  ```

  **Commit**: YES | Message: `refactor(kitty): migrate config to jvf.home` | Files: `modules/programs/kitty/default.nix`


- [x] 6. Migrate `desktop/hyprland/waybar` to `jvf.home` (postInstall tier)

  **What to do**:
  - In `modules/desktop/hyprland/waybar.nix`:
    - Keep package install via wrappers.
    - Replace wrappers config dir declaration with home dir item:
      - target: `.config/waybar` (via `jvf.home.users.${cfg.username}.xdg.config."waybar"`)
      - `kind="dir"`, `mode="copy"`, `source=./assets/waybar/.`.
    - Move `postInstall` to the home item; rely on new env contract (`TARGET_PATH`).

  **Must NOT do**:
  - Don’t change CSS generation logic, only its placement mechanism.

  **Recommended Agent Profile**:
  - Category: `quick` — single file change.
  - Skills: [`writing-nix-code`]

  **Parallelization**: Can Parallel: YES | Wave 3 | Blocks: T7–T8 | Blocked By: T5

  **References**:
  - Existing wrappers usage + postInstall: `modules/desktop/hyprland/waybar.nix:93-105`.

  **Acceptance Criteria**:
  - [ ] `make check` passes.
  - [ ] `nix build .#checks.x86_64-linux.jvf-home-vm --show-trace` passes (ensure VM asserts colors css exists under waybar dir).
  - [ ] Evidence: `.sisyphus/evidence/task-6-waybar-migrate.txt`.

  **QA Scenarios**:
  ```
  Scenario: Waybar assets copied + postInstall writes css
    Tool: Bash
    Steps:
      1) nix build .#checks.x86_64-linux.jvf-home-vm --show-trace
    Expected: VM asserts $HOME/.config/waybar/wallust/colors-waybar.css exists
    Evidence: .sisyphus/evidence/task-6-waybar-migrate.txt
  ```

  **Commit**: YES | Message: `refactor(waybar): migrate assets+postInstall to jvf.home` | Files: `modules/desktop/hyprland/waybar.nix`


- [x] 7. Migrate `programs/claudecode` to `jvf.home` (preserve + custom path + postInstall)

  **What to do**:
  - In `modules/programs/claudecode/default.nix`:
    - Keep wrapper packages in wrappers.
    - Move both config dirs to home:
      - `.claude` dir:
        - `kind="dir"`, `mode="copy"`, `source=<compiled configs dir>`
        - `preserve` = existing preserveFiles list
        - `postInstall` = existing jq logic, but **remove hardcoded `/Users`/`/home`**:
          - use `HOME_DIR` from env and set `CLAUDE_JSON="$HOME_DIR/.claude.json"` and `SETTINGS_JSON="$TARGET_PATH/settings.json"`
      - `.claude-code-router` dir similarly (no postInstall).
    - Ensure wrappers no longer declares `configs/configPath/preserveFiles/postInstall` for these programs (otherwise wrappers→home translation may conflict).
    - Ensure `.claude.json` is still owned by user after postInstall.

  **Must NOT do**:
  - Don’t change mcps/settings generation logic.
  - Don’t touch Darwin `managed-mcp.json` script (out of scope).

  **Recommended Agent Profile**:
  - Category: `unspecified-high` — complex migration, correctness critical.
  - Skills: [`writing-nix-code`] — careful option wiring.

  **Parallelization**: Can Parallel: NO | Wave 3 | Blocks: T8 | Blocked By: T6

  **References**:
  - Current `.claude` wrapper config + postInstall: `modules/programs/claudecode/default.nix:209-273`.
  - Hardcoded paths to remove: `modules/programs/claudecode/default.nix:241-242`.

  **Acceptance Criteria**:
  - [ ] `make check` passes.
  - [ ] `nix build .#checks.x86_64-linux.jvf-home-vm --show-trace` passes (VM asserts preserve+postInstall).
  - [ ] Evidence: `.sisyphus/evidence/task-7-claudecode-migrate.txt`.

  **QA Scenarios**:
  ```
  Scenario: ClaudeCode config swap preserves transcripts
    Tool: Bash
    Steps:
      1) nix build .#checks.x86_64-linux.jvf-home-vm --show-trace
    Expected: VM switches A->B and asserts preserve files survive + claude.json updated
    Evidence: .sisyphus/evidence/task-7-claudecode-migrate.txt
  ```

  **Commit**: YES | Message: `refactor(claudecode): migrate config+preserve+postInstall to jvf.home` | Files: `modules/programs/claudecode/default.nix`


- [ ] 8. Tighten regressions: add explicit conflict tests + document migration pattern

  **What to do**:
  - Extend `modules/checks/home.nix`:
    - Add an eval check that asserts setting both wrappers configs and `jvf.home` for same target fails with expected message.
  - Add a short internal note (code comment only) in `modules/wrappers.nix` describing migration pattern:
    - “packages/wrappers remain in wrappers; home paths/configs go to jvf.home”.

  **Must NOT do**:
  - No docs outside code comments (keep scope tight).

  **Recommended Agent Profile**:
  - Category: `quick`.
  - Skills: [`writing-nix-code`]

  **Parallelization**: Can Parallel: YES | Wave 3 | Blocks: none | Blocked By: T7

  **References**:
  - Conflict policy introduced in T4.

  **Acceptance Criteria**:
  - [ ] `nix build .#checks.x86_64-linux.jvf-home-eval --show-trace` passes.
  - [ ] Evidence: `.sisyphus/evidence/task-8-conflicts.txt`.

  **QA Scenarios**:
  ```
  Scenario: Conflict detection prevents duplicate management
    Tool: Bash
    Steps:
      1) nix build .#checks.x86_64-linux.jvf-home-eval --show-trace
    Expected: passes; includes assertion for conflict case
    Evidence: .sisyphus/evidence/task-8-conflicts.txt
  ```

  **Commit**: YES | Message: `test(home): assert conflicts and document migration contract` | Files: `modules/checks/home.nix modules/wrappers.nix`


## Final Verification Wave (MANDATORY)
- [ ] F1. Plan Compliance Audit — oracle
- [ ] F2. Code Quality Review — unspecified-high
- [ ] F3. Real Manual QA — unspecified-high
- [ ] F4. Scope Fidelity Check — deep

## Commit Strategy
- Keep commits small + bisectable (roughly one TODO per commit).
- Must keep `make check` passing on every commit.

## Success Criteria
- Ergonomic `jvf.home` API available for both OS.
- wrappers no longer does config writes; only wrappers/packages.
- Legacy wrappers configs still work via translation.
- VM test covers: file materialization, dir materialization, postInstall, preserve across A→B switch.
