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

---

## Task Delegation

### Always Use Category Parameter for task()
**Lesson:** When calling `task()`, always provide `category` parameter (e.g., `unspecified-low`, `quick`). The system requires either `category` or `subagent_type`.
**Context:** Forgetting this causes immediate failure with "Invalid arguments: Must provide either category or subagent_type."
**Verify:** Check task call includes `category="..."` before executing.

---

## Dendritic Module Structure

### Export Pattern Must Be `flake.modules.*.*`
**Lesson:** Dendritic aspect files must export as `{ flake.modules.nixos.name = ...; flake.modules.darwin.name = ...; }`, NOT `{ nixos = ...; darwin = ...; }`.
**Context:** Subagents frequently create files with wrong export structure, causing "attribute 'nixos' missing" errors.
**Verify:** `grep "flake.modules" modules/aspects/*.nix` should show the correct pattern.

---

## NixOS Options

### All Options Must Have Defaults for Flake Check
**Lesson:** When defining options in dendritic modules (especially `username`), always add `default = "josevictor";` to prevent "option has no value" assertion failures.
**Context:** 12 program modules failed `nix flake check` because username options lacked defaults — required iterative manual fixes.
**Verify:** Run `nix flake check` immediately after creating modules with options; grep for `default` in option definitions.

### Audit Directory Contents Not Just Task Lists
**Lesson:** Before declaring a migration phase complete, `ls` the source directory to find unlisted modules. Task lists may miss files.
**Context:** Phase 2 task list missed `audio.nix` in `modules/system/`. Discovered only after removing `default.nix`, causing build failure.
**Verify:** Run `ls modules/<category>/` and diff against task list before finalizing any batch migration.

### Clean Host Configs When Removing Legacy Infrastructure
**Lesson:** After removing a legacy module system (e.g., `modules/system/default.nix`), purge host configs of references to removed options like `jvf.system.modules`.
**Context:** Host config had `jvf.system.modules = [ ... ]` and `jvf.system.hostName` (correct: `jvf.system.networking.hostName`). Caused "option does not exist" after legacy removal.
**Verify:** After deleting a `default.nix` aggregator, `grep -r` host configs for any option paths it defined.

### Remove Legacy Imports Immediately After Migration
**Lesson:** When migrating a module to dendritic aspects, immediately remove its import from all role files that reference it. Don't wait for flake check to fail.
**Context:** Phase 5 service migrations left legacy imports in `network-storage.nix` and `ai-development.nix`, causing "option already declared" errors during verification.
**Verify:** `grep -r "../services/<name>.nix" modules/legacy/_/` and remove all matches after creating dendritic aspect.

---

## Context Management

### Prune Aggressively During Refactors
**Lesson:** Large refactoring generates many tool outputs. Prune context after each wave/phase to avoid hitting limits.
**Context:** Nix evaluation outputs, file reads, and bash commands accumulate quickly during multi-wave refactors.
**Verify:** Use `distill` for key findings and `prune` for noise every 3-4 tasks.

---

## Parallel Task Execution

### Avoid Parallel Tasks Modifying Same Files
**Lesson:** When delegating parallel tasks, ensure they modify DISJOINT sets of files. Shared files (core-jvf.nix, host configs) cause coordination deadlocks.
**Context:** Phase 6 hardware migration had 4 parallel agents all trying to modify core-jvf.nix and nixos-desktop.nix — all timed out waiting on each other.
**Verify:** Before parallel delegation, check which files each task will modify. Group by file targets or use sequential execution.

### Use run_in_background=false for File Creation
**Lesson:** File creation tasks should use `run_in_background=false` (synchronous). Background file creation causes race conditions when subsequent tasks need those files.
**Context:** Phase 8 Hyprland used background tasks to create aspects, but host configs referenced them before creation completed — causing "file not found" errors.
**Verify:** If task creates files needed by subsequent tasks in same phase, use synchronous execution.

### Verify File Existence Before Integration
**Lesson:** Before modifying host configs to reference new aspects, verify the aspect files actually exist and are valid.
**Context:** nixos-desktop.nix was updated to reference 16 hyprland aspects, but only 4 existed — caused nix eval failures.
**Verify:** Run `ls modules/aspects/<pattern>` before updating host configs; ensure files exist and `nix flake check` passes.

## Nix String Indentation

- **Rule:** When generating config files (YAML, JSON) in Nix, use `pkgs.formats.*` instead of multi-line strings with `''`. Nix's `''` strings strip minimum indentation, breaking YAML structure.
- **Why:** Wasted 30+ minutes debugging YAML parsing errors caused by Nix string indentation stripping.
- **Check:** If generating structured config, verify output with `cat` after first test run.

## Runtime Path Resolution

- **Rule:** For flake templates needing runtime paths (like `$PWD`), use placeholder substitution (`@@PLACEHOLDER@@` + `sed`) at runtime rather than relying on `projectRoot` which resolves to Nix store paths.
- **Why:** `projectRoot = ./.` in flakes resolves to store path at eval time, not the actual working directory.
- **Check:** Test with `nix develop --impure --command bash -c 'echo $SANDBOX_STATE'` and verify paths point to working directory.

## Process-Compose Commands

- **Rule:** `process-compose up` uses `-f` for config file; `process-compose down/ps` use `-U -u <socket>` for Unix socket connection. Use `-D` (not `-d`) for detached mode.
- **Why:** Wrong flags cause "unknown shorthand flag" errors or connection failures.
- **Check:** Run `process-compose <cmd> --help` to verify correct flags before implementing.

## Nix Flake with Sockets

- **Rule:** When running `nix develop` multiple times in a directory with Unix sockets (`.sock` files) or special files, Nix will fail with "unsupported type". Clean state directory before re-evaluating flake.
- **Why:** Nix cannot handle socket files in flake source tree during evaluation.
- **Check:** If seeing "unsupported type" errors, run `rm -rf .sandbox-state` before `nix develop`.
