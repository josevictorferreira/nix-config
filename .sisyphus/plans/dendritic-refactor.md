# Dendritic refactor (flake-parts + import-tree) for this repo

## TL;DR
> Move from host-centric/manual imports to **Dendritic**: feature/aspect-oriented, **flake-parts** driven, modules auto-discovered via **import-tree**. Keep **2 hosts** outputs stable: `.#nixosConfigurations.nixos-desktop` and `.#darwinConfigurations.macos-macbook`. Keep **`jvf.*` option layer** + **`jvf.wrappers`** (no Home Manager migration now). Maintain green at every step (`make check`, `make rebuild` / `make rebuildd`).

**Deliverables**
- `flake.nix` re-based on `flake-parts` and `import-tree`
- New dendritic module tree: `modules/aspects/**` + `modules/hosts/**` + `modules/legacy/_/**` (ignored by import-tree)
- Host wiring as aspects list (dendritic-native) but still setting `jvf.system.modules` / `jvf.roles.active` etc.
- Secrets (`sops-nix`) still integrated for NixOS + Darwin.
- Preserve existing per-system behavior: overlays (bun2nix), formatter, templates, distro-grub-themes (NixOS).

**Effort**: Large
**Parallel execution**: YES (waves)
**Critical path**: foundation flake-parts scaffold → legacy segregation → host wiring → migrate aspects → final cleanup

---

## Context

### Original request
- Refactor this NixOS/Darwin unified repo to **Dendritic** pattern: feature/aspect-oriented, using **flake-parts + import-tree**.
- Keep it **simple**.
- Support 2 hosts: **x86_64-linux NixOS** + **aarch64-darwin nix-darwin**.
- Consider Home Manager only if simpler; user decided **keep wrappers**.

### Interview decisions (confirmed)
- Home Manager: **KEEP current `jvf.wrappers`** (no HM migration now)
- Keep `jvf.*` option layer/roles: **YES**
- Host selection model: **aspects list** (dendritic-native)
- Verification bar: **rebuild-only** (no broken intermediate steps)

### Current repo constraints (must preserve)
- Flake outputs/hostnames must remain:
  - `.#nixosConfigurations.nixos-desktop`
  - `.#darwinConfigurations.macos-macbook`
- Makefile commands depend on that:
  - `make check` → `nix flake check --show-trace`
  - `make rebuild` / `make rebuildd`
  - `make format` / `make lint` use `nix fmt`

### Metis review (gaps addressed in plan)
- Explicitly plan how to replace current `specialArgs` usage (username/host/os/system/inputs.lib)
- Explicitly plan `sops-nix` integration in dendritic structure
- Guardrail: **import-tree** must not accidentally import old nix modules; segregate legacy under paths containing `/_`

---

## Work objectives

### Core objective
Adopt a Dendritic (flake-parts + import-tree) structure while preserving existing behavior (jvf options, wrappers, roles) and keeping both host rebuilds working at each step.

### Must have
- `make check` succeeds at each step.
- `make rebuild` works on Linux host output name; `make rebuild` works on Darwin output name.
- `jvf.wrappers` still functions (no behavior regression).

### Must NOT have (guardrails)
- No Home Manager migration in this refactor.
- No broken intermediate commits (no “big bang” breakage).
- No `builtins.currentSystem` usage.
- No import-tree importing legacy NixOS/Darwin modules accidentally.

---

## Verification strategy

### Test decision
- Infra exists: Nix eval/check + rebuild scripts via Makefile.
- Automated unit tests: N/A.

### QA policy (agent-executable)
Per task, executor runs:
- `nix flake check --show-trace`
- `nix eval` smoke checks (see each task)
- When relevant: `nix build .#darwinConfigurations.macos-macbook.system` (Darwin) and/or `nix eval .#nixosConfigurations.nixos-desktop.config.system.build.toplevel.outPath`

Evidence saved to `.sisyphus/evidence/task-N-*.txt`.

---

## Execution strategy (parallel waves)

Wave 1 (foundation; parallel): create flake-parts scaffold + legacy segregation + args strategy.

Wave 2 (host wiring; parallel): wire nixos-desktop + macos-macbook using aspects list.

Wave 3 (aspects migration; parallel): move jvf aggregators + key modules into dendritic aspects.

Wave 4 (cleanup; parallel): remove remaining legacy wiring, ensure import-tree coverage, docs/README updates (if any).

---

## TODOs

> NOTE: “references” are the only context the executor gets. Each task includes concrete file refs.

### Wave 1 — scaffold + guardrails

- [x] 1. Add flake-parts + import-tree skeleton (no behavior change yet)

  **What to do**:
  - Introduce flake-parts in `flake.nix` (or split into `flake/` if preferred) but keep outputs identical.
  - Add `imports = [ (inputs.import-tree ./modules) ];` (or equivalent), but ensure legacy code is ignored by path convention.
  - Keep `systems = [ "x86_64-linux" "aarch64-darwin" ]` in flake-parts.

  **Must NOT do**:
  - Don’t move modules yet if it breaks.

  **Recommended Agent Profile**:
  - Category: `quick`
  - Skills: `writing-nix-code`, `managing-flakes`

  **Parallelization**:
  - Can Run In Parallel: YES (with tasks 2-3)
  - Blocks: 4-8

  **References**:
  - `flake.nix` (current: manual outputs, specialArgsFor, mkPkgs)
  - Dendrix guide: use `flake-parts.lib.mkFlake` + `import-tree`

  **Acceptance Criteria**:
  - [ ] `nix flake check --show-trace` → PASS
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.system.build.toplevel.outPath` returns store path
  - [ ] `nix eval .#darwinConfigurations.macos-macbook.config.system.build.toplevel.outPath` returns store path
  - [ ] `nix eval .#formatter.x86_64-linux.outPath` evaluates (formatter preserved)

  **QA Scenarios**:
  ```
  Scenario: flake-parts scaffold doesn't break outputs
    Tool: Bash
    Steps:
      1. run: nix flake check --show-trace
      2. run: nix eval .#nixosConfigurations.nixos-desktop.config.system.build.toplevel.outPath
      3. run: nix eval .#darwinConfigurations.macos-macbook.config.system.build.toplevel.outPath
    Expected: all exit 0; evals return /nix/store/... strings
    Evidence: .sisyphus/evidence/task-1-flake-scaffold.txt
  ```

- [x] 2. Create "legacy ignored" area and move non-flake-parts modules there (guardrail)

  **What to do**:
  - Create `modules/legacy/_/` (or similar path containing `/_`) and move existing non-dendritic NixOS/Darwin modules there *without changing content*.
  - Keep a thin compatibility layer (temporary importers) so existing host rebuild still works.

  **Notes**:
  - Do this incrementally (directory-by-directory) to keep `make check` green.

  **Recommended Agent Profile**:
  - Category: `quick`
  - Skills: `writing-nix-code`

  **Parallelization**:
  - Can Run In Parallel: YES (with 1 and 3)
  - Blocks: 5-12

  **References**:
  - import-tree ignore rule: any path containing `/_`
  - Current module trees to move under ignored path:
    - `modules/system/**`
    - `modules/roles/**`
    - `modules/users/**`
    - `modules/hardware/**`
    - `modules/services/**`
    - `modules/programs/**`
    - `modules/desktop/**`

  **Acceptance Criteria**:
  - [ ] `nix flake check --show-trace` → PASS

  **QA Scenarios**:
  ```
  Scenario: import-tree does not auto-import legacy
    Tool: Bash
    Steps:
      1. run: nix flake check --show-trace
    Expected: PASS; no unexpected option collisions due to double-import
    Evidence: .sisyphus/evidence/task-2-legacy-ignore.txt
  ```

- [x] 3. Replace current `specialArgs` contract with explicit config options / `_module.args` shim

  **What to do**:
  - Decide a minimal mechanism to provide `username`, `host`, `os` to modules without widespread specialArgs:
    - Preferred: add `jvf.core.username`, `jvf.core.host`, `jvf.core.os` options and set in host module.
    - Transitional: set `_module.args.username = ...` only for role modules that require it (until migrated).
  - Reduce reliance on `system` arg by using `pkgs.stdenv.isDarwin` where feasible (wrappers/users modules).

  **Recommended Agent Profile**:
  - Category: `unspecified-high`
  - Skills: `writing-nix-code`

  **Parallelization**:
  - Can Run In Parallel: YES (with 1-2)
  - Blocks: 6-12

  **References**:
  - `modules/roles/default.nix` currently expects `username` arg
  - `modules/users/default.nix`, `modules/users/wrappers.nix` currently use `system` arg

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.roles.active` returns list
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.users.josevictor.enable` evaluates
  - [ ] `nix eval .#darwinConfigurations.macos-macbook.config.jvf.users.josevictorferreira.enable` evaluates

  **QA Scenarios**:
  ```
  Scenario: modules still receive required per-host identity
    Tool: Bash
    Steps:
      1. run: nix eval .#nixosConfigurations.nixos-desktop.config.jvf.system.hostName
      2. run: nix eval .#darwinConfigurations.macos-macbook.config.system.primaryUser
    Expected: values match host/user
    Evidence: .sisyphus/evidence/task-3-args-shim.txt
  ```

### Wave 2 — hosts as aspects lists

- [x] 4. Create dendritic host aspect: `nixos-desktop` selector

  **What to do**:
  - Add `modules/hosts/nixos-desktop.nix` (flake-parts module) that defines `flake.nixosConfigurations.nixos-desktop = ...`.
  - In host’s `modules = with inputs.self.modules.nixos; [ ...aspects... ] ++ [ ./hosts/nixos-desktop/config.nix ]` (or move host config content to aspect).
  - Ensure the host imports remain minimal and deterministic.

  **Recommended Agent Profile**:
  - Category: `writing-nix-code`
  - Skills: `writing-nix-code`, `managing-flakes`

  **Parallelization**:
  - Can Run In Parallel: YES (with task 5)
  - Blocked By: 1-3

  **References**:
  - Existing output name: `flake.nix` defines nixosConfigurations.nixos-desktop
  - Existing host module: `hosts/nixos-desktop/config.nix`

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.system.build.toplevel.outPath` returns store path

  **QA Scenarios**:
  ```
  Scenario: nixos-desktop wiring via aspects
    Tool: Bash
    Steps:
      1. nix eval .#nixosConfigurations.nixos-desktop.config.system.build.toplevel.outPath
    Expected: store path string
    Evidence: .sisyphus/evidence/task-4-nixos-host.txt
  ```

- [ ] 5. Create dendritic host aspect: `macos-macbook` selector

  **What to do**:
  - Add `modules/hosts/macos-macbook.nix` defining `flake.darwinConfigurations.macos-macbook = ...`.
  - Keep `sops-nix` module included.

  **Recommended Agent Profile**:
  - Category: `writing-nix-code`
  - Skills: `writing-nix-code`, `managing-flakes`

  **Parallelization**:
  - Can Run In Parallel: YES (with task 4)
  - Blocked By: 1-3

  **References**:
  - Existing output name: `flake.nix` defines darwinConfigurations.macos-macbook
  - Existing host module: `hosts/macos-macbook/config.nix`

  **Acceptance Criteria**:
  - [ ] `nix eval .#darwinConfigurations.macos-macbook.config.system.build.toplevel.outPath` returns store path
  - [ ] `nix build .#darwinConfigurations.macos-macbook.system` succeeds (on darwin-capable runner)

  **QA Scenarios**:
  ```
  Scenario: macos-macbook wiring via aspects
    Tool: Bash
    Steps:
      1. nix eval .#darwinConfigurations.macos-macbook.config.system.build.toplevel.outPath
    Expected: store path
    Evidence: .sisyphus/evidence/task-5-darwin-host.txt
  ```

### Wave 3 — aspects migrate existing modules (keep jvf.*)

- [ ] 6. Add aspect: `core-jvf` (imports jvf aggregators + users + wrappers)

  **What to do**:
  - Create `modules/aspects/core-jvf.nix` that contributes:
    - `flake.modules.nixos.core-jvf.imports` should mirror *current* flake module list (from old `flake.nix`) but pointing to legacy paths, e.g.:
      - `./legacy/_/users/repositories.nix`
      - `./legacy/_/users/wrappers.nix`
      - `./legacy/_/users/default.nix`
      - `./legacy/_/hardware/default.nix`
      - `./legacy/_/system/default.nix`
      - `./legacy/_/roles/default.nix`
      - (NixOS-only) `distro-grub-themes` stays separate (task 11)
    - same for `flake.modules.darwin.core-jvf`.
  - Ensure `jvf.*` options are still defined exactly once.

  **Recommended Agent Profile**:
  - Category: `unspecified-high`
  - Skills: `writing-nix-code`

  **Parallelization**:
  - Can Run In Parallel: YES (with 7-8)
  - Blocked By: 1-3

  **References**:
  - Aggregators: `modules/system/default.nix`, `modules/roles/default.nix`
  - User/wrapper modules: `modules/users/default.nix`, `modules/users/wrappers.nix`

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.system.modules` works
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.options.jvf.wrappers.users.type.name` evaluates

  **QA Scenarios**:
  ```
  Scenario: jvf core aspect provides options
    Tool: Bash
    Steps:
      1. nix eval .#nixosConfigurations.nixos-desktop.options.jvf.system.modules.type.name
      2. nix eval .#darwinConfigurations.macos-macbook.options.jvf.users.type.name
    Expected: both eval succeed
    Evidence: .sisyphus/evidence/task-6-core-jvf.txt
  ```

- [ ] 7. Add aspects: `desktop-hyprland` (nixos only) and `darwin-defaults` (darwin only)

  **What to do**:
  - `desktop-hyprland` aspect imports existing hyprland module tree (likely legacy path initially) and sets any enable defaults needed.
  - `darwin-defaults` aspect imports host’s darwin defaults logic if you decide to split it out of host file; otherwise keep host-local.

  **Recommended Agent Profile**:
  - Category: `unspecified-high`
  - Skills: `writing-nix-code`

  **Parallelization**:
  - Can Run In Parallel: YES
  - Blocked By: 1-3

  **References**:
  - `modules/desktop/hyprland/**` (current)
  - `hosts/macos-macbook/config.nix` (current)

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.desktop.hyprland.enable` true
  - [ ] `nix eval .#darwinConfigurations.macos-macbook.config.system.defaults.NSGlobalDomain.KeyRepeat` evaluates

  **QA Scenarios**:
  ```
  Scenario: nixos desktop aspect still toggles hyprland
    Tool: Bash
    Steps:
      1. nix eval .#nixosConfigurations.nixos-desktop.config.jvf.desktop.hyprland.enable
    Expected: true
    Evidence: .sisyphus/evidence/task-7-hyprland-enable.txt

  Scenario: darwin defaults still evaluate
    Tool: Bash
    Steps:
      1. nix eval .#darwinConfigurations.macos-macbook.config.system.defaults.NSGlobalDomain.KeyRepeat
    Expected: integer value
    Evidence: .sisyphus/evidence/task-7-darwin-defaults.txt
  ```

- [ ] 8. Add aspect: `secrets-sops` (nixos + darwin)

  **What to do**:
  - Create `modules/aspects/secrets-sops.nix` that:
    - imports `sops-nix.nixosModules.sops` into nixos class
    - imports `sops-nix.darwinModules.sops` into darwin class
  - Ensure `.sops.yaml` and `secrets/secrets.enc.yaml` locations remain.

  **Recommended Agent Profile**:
  - Category: `quick`
  - Skills: `writing-nix-code`

  **Parallelization**:
  - Can Run In Parallel: YES
  - Blocked By: 1

  **References**:
  - `.sops.yaml`
  - `secrets/secrets.enc.yaml`
  - Current flake imports: `sops-nix.nixosModules.sops`, `sops-nix.darwinModules.sops`

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.sops` evaluates (attrset)
  - [ ] `nix eval .#darwinConfigurations.macos-macbook.config.sops` evaluates

  **QA Scenarios**:
  ```
  Scenario: sops module present on both hosts
    Tool: Bash
    Steps:
      1. nix eval .#nixosConfigurations.nixos-desktop.config.sops
      2. nix eval .#darwinConfigurations.macos-macbook.config.sops
    Expected: both eval succeed
    Evidence: .sisyphus/evidence/task-8-sops-present.txt
  ```

- [ ] 9. Add perSystem aspect: overlays + pkgs policy (bun2nix, allowUnfree)

  **What to do**:
  - Under flake-parts `perSystem`, define pkgs import with:
    - correct `nixpkgs` vs `nixpkgs-darwin` selection
    - `config.allowUnfree = true`
    - overlays include `bun2nix.overlays.default` (and any existing overlays)
  - Ensure `nix fmt` still uses `nixpkgs-fmt`.

  **Recommended Agent Profile**:
  - Category: `unspecified-high`
  - Skills: `managing-flakes`, `writing-nix-code`

  **Parallelization**:
  - Can Run In Parallel: YES
  - Blocked By: 1

  **References**:
  - `flake.nix`: `mkPkgs` + overlay + allowUnfree + formatter wiring (current)

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.nixpkgs.config.allowUnfree` → true
  - [ ] `nix eval .#darwinConfigurations.macos-macbook.config.nixpkgs.config.allowUnfree` → true
  - [ ] `nix fmt -- --check .` passes (or `make lint`)

  **QA Scenarios**:
  ```
  Scenario: perSystem pkgs works for both systems
    Tool: Bash
    Steps:
      1. nix eval .#nixosConfigurations.nixos-desktop.config.nixpkgs.config.allowUnfree
      2. nix eval .#darwinConfigurations.macos-macbook.config.nixpkgs.config.allowUnfree
    Expected: both true
    Evidence: .sisyphus/evidence/task-9-perSystem.txt
  ```

### Wave 4 — switch hosts to pure aspects + cleanup

- [ ] 10. Convert host configs to “aspects list” only (minimize direct imports)

  **What to do**:
  - Update host modules to select aspects explicitly:
    - NixOS host uses `[ core-jvf secrets-sops desktop-hyprland ... ]`.
    - Darwin host uses `[ core-jvf secrets-sops ... ]`.
  - Keep host-local unique settings (static IP, system.defaults) in host file.

  **Recommended Agent Profile**:
  - Category: `unspecified-high`
  - Skills: `writing-nix-code`

  **Parallelization**:
  - Can Run In Parallel: NO (touches both hosts; do after 4-8)

  **Acceptance Criteria**:
  - [ ] `make check` passes
  - [ ] `nix eval` for both toplevels returns store paths

  **QA Scenarios**:
  ```
  Scenario: both hosts still evaluate after host cleanup
    Tool: Bash
    Steps:
      1. make check
      2. nix eval .#nixosConfigurations.nixos-desktop.config.system.build.toplevel.outPath
      3. nix eval .#darwinConfigurations.macos-macbook.config.system.build.toplevel.outPath
    Expected: all succeed
    Evidence: .sisyphus/evidence/task-10-host-cleanup.txt
  ```

- [ ] 11. Re-add NixOS-only dependency: distro-grub-themes (as aspect)

  **What to do**:
  - Create `modules/aspects/boot-grub-theme.nix` (nixos only) that imports `distro-grub-themes.nixosModules.<system>.default` (or equivalent safe approach).
  - Ensure it’s selected by nixos-desktop host aspects.

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.boot.loader.grub.enable` evaluates

  **QA Scenarios**:
  ```
  Scenario: nixos grub theme module still imported
    Tool: Bash
    Steps:
      1. nix eval .#nixosConfigurations.nixos-desktop.config.boot.loader.grub.enable
    Expected: eval succeeds (bool)
    Evidence: .sisyphus/evidence/task-11-grub-theme.txt
  ```

- [ ] 12. Remove remaining legacy compatibility wiring; ensure import-tree is sole import mechanism

  **What to do**:
  - Verify no non-ignored `modules/**` paths contain old NixOS/Darwin modules.
  - Ensure each dendritic `.nix` under `modules/` is a flake-parts module (not a NixOS module).
  - Keep legacy NixOS/Darwin modules only under `modules/legacy/_/**`.

  **Acceptance Criteria**:
  - [ ] `make check` passes
  - [ ] `nix flake check --show-trace` passes

  **QA Scenarios**:
  ```
  Scenario: import-tree + module classes are clean
    Tool: Bash
    Steps:
      1. make check
    Expected: PASS; no duplicate option definitions from accidental imports
    Evidence: .sisyphus/evidence/task-12-import-tree-clean.txt
  ```

  **What to do**:
  - Ensure only dendritic flake-parts modules live under `modules/` (non-ignored paths).
  - Legacy NixOS/Darwin modules remain under `modules/legacy/_/**` until migrated fully.
  - Confirm no double-import of same module.

  **Recommended Agent Profile**:
  - Category: `quick`
  - Skills: `writing-nix-code`

  **Acceptance Criteria**:
  - [ ] `nix flake check --show-trace` PASS
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.system.modules` works

---

## Final verification wave (after all tasks)

- [ ] F1. Nix evaluation + output audit
  - Run:
    - `make check`
    - `nix eval .#nixosConfigurations.nixos-desktop.config.system.build.toplevel.outPath`
    - `nix eval .#darwinConfigurations.macos-macbook.config.system.build.toplevel.outPath`
  - Confirm wrappers still present:
    - `nix eval .#nixosConfigurations.nixos-desktop.options.jvf.wrappers.users.type.name`
  - Evidence: `.sisyphus/evidence/final-flake-audit.txt`

---

## Target directory structure (after full refactor)

```text
.
├── flake.nix
├── Makefile
├── .sops.yaml
├── secrets/
│   └── secrets.enc.yaml
├── hosts/
│   ├── nixos-desktop/
│   │   ├── config.nix              # host-local settings only (static IP, stateVersion, etc)
│   │   ├── hardware.nix            # host-local hardware config
│   │   └── variables.nix
│   └── macos-macbook/
│       ├── config.nix              # host-local darwin defaults, stateVersion, etc
│       └── variables.nix
├── modules/
│   ├── hosts/
│   │   ├── nixos-desktop.nix       # flake.nixosConfigurations.nixos-desktop
│   │   └── macos-macbook.nix       # flake.darwinConfigurations.macos-macbook
│   ├── aspects/
│   │   ├── core-jvf.nix            # imports jvf aggregators/users/wrappers (as flake.modules.*)
│   │   ├── secrets-sops.nix        # imports sops modules (nixos+darwin)
│   │   ├── desktop-hyprland.nix    # nixos-only aspect
│   │   └── darwin-defaults.nix     # darwin-only aspect (optional)
│   ├── pkgs/
│   │   └── overlays.nix            # bun2nix overlay wiring (perSystem)
│   └── legacy/
│       └── _/
│           ├── system/             # moved from modules/system
│           ├── roles/              # moved from modules/roles
│           ├── users/              # moved from modules/users
│           ├── hardware/           # moved from modules/hardware
│           ├── services/           # moved from modules/services
│           ├── programs/           # moved from modules/programs
│           └── desktop/            # moved from modules/desktop
├── lib/                            # keep (but reduce reliance on specialArgs)
└── templates/
```

---

## Commit strategy (executor)
- Commit after each task or small batch while keeping `make check` green.
- Prefer messages: `refactor(dendritic): <small step>`.

---

## Success criteria
- [ ] `make check` PASS
- [ ] `make rebuild` PASS on Linux; `make rebuild` PASS on Darwin
- [ ] Hostnames unchanged: `nixos-desktop`, `macos-macbook`
- [ ] `jvf.*` options and `jvf.wrappers` still function
