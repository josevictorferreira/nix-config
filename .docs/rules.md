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

### Phase Large File Reorganizations
**Lesson:** When moving 50+ files, split into phases: (1) batch move files, (2) fix relative path references, (3) update entry points, (4) verify build. Never combine file moves with path fixes in one step.
**Context:** Moving 87 .nix files from flat `modules/aspects/` to categorized dirs required fixing 14 asset path references and simplifying flake.nix — doing all at once would have been error-prone.
**Verify:** After each phase, run `nix flake check` before proceeding to next phase.

---

## Dendritic Pattern

### import-tree Scans Recursively, Ignores `/_` Paths
**Lesson:** import-tree discovers ALL `.nix` files under its root directory. Paths containing `/_` are excluded from auto-import.
**Context:** Used for NixOS-level helper modules (e.g., `modules/core/_/options.nix`) that shouldn't be imported as flake-parts modules.
**Verify:** Confirm flake.nix uses `(inputs.import-tree ./modules)` and helper modules are in `/_` paths.

### Single import-tree Call for Recursive Discovery
**Lesson:** Use one `(inputs.import-tree ./modules)` call instead of multiple calls to subdirectories. import-tree recursively discovers all `.nix` files, so subdirectory structure is purely organizational.
**Context:** Originally had 3 separate import-tree calls for `./modules/flake`, `./modules/hosts`, `./modules/aspects`. Consolidating to one call simplified flake.nix and made directory reorganization transparent.
**Verify:** `grep "import-tree" flake.nix` should show exactly one call (plus the input declaration).

### Per-Module Folder Organization
**Lesson:** Programs go in `modules/programs/<name>/default.nix`. System/services/roles/hardware use flat `.nix` files in category dirs.
**Context:** Per-program folders allow co-location of assets, secrets, and related files. Flat structure for system modules keeps simple things simple.
**Verify:** New programs create `modules/programs/<name>/default.nix`, not `modules/aspects/programs-<name>.nix`.

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
**Verify:** Run `git add modules/<category>/<name>.nix` immediately after creating the file, before any Nix command.

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

---

## Dendritic Module Structure

### Export Pattern Must Be `flake.modules.*.*`
**Lesson:** Dendritic aspect files must export as `{ flake.modules.nixos.name = ...; flake.modules.darwin.name = ...; }`, NOT `{ nixos = ...; darwin = ...; }`.
**Context:** Subagents frequently create files with wrong export structure, causing "attribute 'nixos' missing" errors.
**Verify:** `grep "flake.modules" modules/programs/*/default.nix modules/system/*.nix modules/services/*.nix modules/roles/*.nix` should show the correct pattern.

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

### Clean Host Configs After Major Restructuring
**Lesson:** After removing or restructuring module systems, purge host configs of references to removed options.
**Context:** Host config had `jvf.system.modules = [ ... ]` and old option paths that no longer existed after restructuring.
**Verify:** After major changes, `grep -r` host configs for any option paths that may have been affected.

### Define Package Option Values in Config
**Lesson:** When a module builds a package and exposes it via an option, always set the option value in the config section.
**Context:** `programs-ck-search.nix` built `ckSearchPkg` but never assigned it to `jvf.programs.ck-search.package`, causing "option accessed but has no value" errors when other modules tried to use it.
**Verify:** Ensure modules set `cfg.package = lib.mkDefault builtPackage;` in their config section if other modules depend on the package option.

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
**Verify:** Run `ls modules/<category>/<pattern>` before updating host configs; ensure files exist and `nix flake check` passes.

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

## Module Directory Management

### Check All References Before Deleting Directories
**Lesson:** Before deleting any module directory, grep for ALL references including indirect imports via other modules.
**Context:** Hidden imports in unrelated files often fail only after deletion during nix flake check.
**Verify:** Run `grep -r "modules/<dir>" --include="*.nix" .` and fix all matches before `rm -rf`.

### Distinguish Config Files from Nix Modules
**Lesson:** When moving config files (like desktop dotfiles), copy only static config - NOT default.nix or other Nix module files.
**Context:** Copied Nix module files to assets/ causing "undefined variable" errors. Config assets should be JSON/YAML/plain files only.
**Verify:** After copying, check that assets/ contains no `*.nix` files - only actual config files.

### Recover Deleted Content from Git
**Lesson:** If you delete files that are still needed, use `git show HEAD:path/to/file` to recover content without restoring files.
**Context:** Had to recover development module content from git after premature deletion to inline into programs-neovim.nix.
**Verify:** `git show HEAD:path` works even for deleted files if they've been committed before.

## Nixpkgs Lib Functions

### pkgs.formats for Structured Config
**Lesson:** Use `pkgs.formats.json { }` (not `lib.formats` or `pkgs.lib.formats`) for generating structured config in NixOS modules.
**Context:** `lib.formats` is not available in module lib context; `formats` is an attribute of nixpkgs pkgs, not lib.
**Verify:** Test with `nix repl '<nixpkgs>'` then `:pkgs.formats.json { }` to confirm.

## Shell Script Builders

### writeShellApplication Runs ShellCheck
**Lesson:** `pkgs.writeShellApplication` runs shellcheck validation; use `pkgs.writeScriptBin` to skip validation for scripts with complex quoted text.
**Context:** RFC2119 text in prompt-enhancer contained quotes that caused shellcheck failures. writeScriptBin doesn't run shellcheck.
**Verify:** If script fails with "SC1078" or "SC1079" errors, switch to writeScriptBin.

## Module Option Values

### Enable Options Must Be Set in Host Configs
**Lesson:** Aspects with enable options require explicit `enable = true;` in host configs for their config to take effect.
**Context:** `jvf.system.nixpkgs.enable` was missing from host config, so allowUnfree settings never applied, causing Steam build failure.
**Verify:** After adding an aspect to imports, check if it has required enable options that need setting in host config.
