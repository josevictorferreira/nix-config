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

---

## Context Management

### Prune Aggressively During Refactors
**Lesson:** Large refactoring generates many tool outputs. Prune context after each wave/phase to avoid hitting limits.
**Context:** Nix evaluation outputs, file reads, and bash commands accumulate quickly during multi-wave refactors.
**Verify:** Use `distill` for key findings and `prune` for noise every 3-4 tasks.
