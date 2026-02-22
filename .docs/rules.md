# Project Rules & Learnings

Critical lessons from past sessions to avoid repeated friction.

---

## Task Delegation

### Always Use Category Parameter
**Lesson:** When calling `task()`, always provide `category` parameter (e.g., `unspecified-high`, `quick`). The system requires either `category` or `subagent_type`.
**Context:** Forgetting this causes immediate failure with "Invalid arguments: Must provide either category or subagent_type."
**Verify:** Check task call includes `category="..."` before executing.

---

## File Operations

### Moving Modules Breaks Relative Imports
**Lesson:** When moving Nix modules to different directory depths, update all relative `import ../../..` paths accordingly.
**Context:** Moving `modules/programs/zsh/` to `modules/legacy/_/programs/zsh/` broke imports that referenced `../../../../lib`.
**Verify:** After `mv` operations, run `nix flake check` to catch broken imports immediately.

---

## Dendritic Pattern

### import-tree Ignores Paths with `/_`
**Lesson:** Place legacy/non-dendritic modules under paths containing `/_` (e.g., `modules/legacy/_/`) to exclude them from auto-import.
**Context:** import-tree scans directories but skips any path containing `/_` substring.
**Verify:** Confirm `modules/legacy/_/` exists and flake.nix uses `(inputs.import-tree ./modules)`.

---

## Verification

### Never Trust Subagent Success Claims
**Lesson:** Always run verification commands yourself after task completion. Subagents frequently claim success with incomplete/broken work.
**Context:** Automated checks pass but manual code review often reveals logic errors, missing edge cases, or incomplete implementations.
**Verify:** Run `nix flake check` and eval tests after EVERY task completion before proceeding.

---

## Dendritic Migration

### git add Before nix eval in Flakes
**Lesson:** Always `git add` new files before running `nix eval` or `nix flake check`. Flakes use pure evaluation — untracked files are invisible.
**Context:** Every migration task creates a new aspect file. Forgetting `git add` causes cryptic "file not found" errors during verification.
**Verify:** Run `git add modules/aspects/<name>.nix` immediately after creating the file, before any Nix command.

### 4-File Checklist Per Aspect Migration
**Lesson:** Each dendritic aspect migration touches exactly 4 files: (1) create `modules/aspects/<name>.nix`, (2) remove legacy import from `core-jvf.nix`, (3) add to `nixos-desktop.nix` aspects list, (4) add to `macos-macbook.nix` aspects list.
**Context:** Phase 1 tasks 1-3 all followed this identical pattern. Missing any file causes duplicate option definitions or missing config.
**Verify:** After each migration, confirm all 4 files are in `git diff --stat`.

### Parameterize isDarwin Instead of specialArgs
**Lesson:** Use `mkConfig { isDarwin }` closure pattern instead of relying on `system` specialArg for platform branching. Hardcode `isDarwin = true/false` in each platform module.
**Context:** Legacy modules used `system` specialArg to detect Darwin, risking infinite recursion. Dendritic pattern eliminates this — platform is known at module definition time.
**Verify:** New aspect files should never reference `system` or `pkgs.stdenv.isDarwin` for top-level config branching.

### Darwin Configs Only Fully Validate on macOS
**Lesson:** `nix flake check` on Linux skips `darwinConfigurations` eval (incompatible system). Use `nix eval .#darwinConfigurations.<host>.options.<path>` for targeted Darwin option type-checks on Linux.
**Context:** Phase 1 verified NixOS fully but Darwin only via `nix eval` type probes. Structural errors in Darwin modules may go undetected until macOS rebuild.
**Verify:** Always run both `nix eval .#darwinConfigurations...` AND `nix flake check` — they catch different classes of errors.

### Coordinate Subsystem Ownership Between Modules
**Lesson:** When two aspect modules configure the same subsystem (e.g., sops), one must own the config and the other must only consume it. Never split `defaultSopsFile`/`age.keyFile` across modules.
**Context:** `system-security.nix` and `secrets-sops.nix` both touched sops config, causing "No key source configured" assertion. Fix: single owner for sops base config.
**Verify:** Before creating an aspect that uses sops/networking/etc, `grep -r` for existing config of that subsystem across all aspects.

### Use Relative Paths Not inputs.self in Aspects
**Lesson:** Dendritic aspect modules can't access `inputs.self` directly. Use relative paths (e.g., `./../../secrets/secrets.enc.yaml`) for file references within the repo.
**Context:** Legacy modules used `${inputs.self}/secrets/...` for sops files. Aspect modules lack `inputs` in scope — `config._module.args.self.outPath` doesn't work either.
**Verify:** New aspects should never reference `inputs.self`. Use `../..` relative paths from the aspect file location.

### Don't Bridge Legacy Enable Patterns During Migration
**Lesson:** When migrating a module to dendritic, use only `lib.mkIf cfg.enable`. Don't create `enableEffective` bridges that OR legacy `config.jvf.system.modules` lists with new `cfg.enable`.
**Context:** A subagent created `enableEffective = cfg.enable || legacyEnabled` referencing the old modules list — caused "undefined variable" errors and unnecessary complexity.
**Verify:** Aspect modules should have zero references to `config.jvf.system.modules` or `config.jvf.*.modules`.

### Audit Directory Contents Not Just Task Lists
**Lesson:** Before declaring a migration phase complete, `ls` the source directory to find unlisted modules. Task lists may miss files.
**Context:** Phase 2 task list missed `audio.nix` in `modules/system/`. Discovered only after removing `default.nix`, causing build failure.
**Verify:** Run `ls modules/<category>/` and diff against task list before finalizing any batch migration.

### Clean Host Configs When Removing Legacy Infrastructure
**Lesson:** After removing a legacy module system (e.g., `modules/system/default.nix`), purge host configs of references to removed options like `jvf.system.modules`.
**Context:** Host config had `jvf.system.modules = [ ... ]` and `jvf.system.hostName` (correct: `jvf.system.networking.hostName`). Caused "option does not exist" after legacy removal.
**Verify:** After deleting a `default.nix` aggregator, `grep -r` host configs for any option paths it defined.

---

## Context Management

### Prune Aggressively During Refactors
**Lesson:** Large refactoring generates many tool outputs. Prune context after each wave/phase to avoid hitting limits.
**Context:** Nix evaluation outputs, file reads, and bash commands accumulate quickly during multi-wave refactors.
**Verify:** Use `distill` for key findings and `prune` for noise every 3-4 tasks.
