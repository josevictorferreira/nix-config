# Project Rules & Learnings

Critical lessons from past sessions to avoid repeated friction.

---

## Task Delegation

### Always Use Category Parameter
**Lesson:** When calling `task()`, always provide `category` parameter (e.g., `unspecified-high`, `quick`). The system requires either `category` or `subagent_type`.
**Context:** Forgetting this causes immediate failure with "Invalid arguments: Must provide either category or subagent_type."
**Verify:** Check task call includes `category="..."` before executing.

---

## Dendritic Pattern (Active)

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

### Export Pattern Must Be `flake.modules.*.*`
**Lesson:** Dendritic aspect files must export as `{ flake.modules.nixos.name = ...; flake.modules.darwin.name = ...; }`, NOT `{ nixos = ...; darwin = ...; }`.
**Context:** Subagents frequently create files with wrong export structure, causing "attribute 'nixos' missing" errors.
**Verify:** `grep "flake.modules" modules/programs/*/default.nix modules/system/*.nix modules/services/*.nix modules/roles/*.nix` should show the correct pattern.

### Use Relative Paths Not inputs.self in Aspects
**Lesson:** Dendritic aspect modules can't access `inputs.self` directly. Use relative paths (e.g., `./../../secrets/secrets.enc.yaml`) for file references within the repo.
**Context:** Legacy modules used `${inputs.self}/secrets/...` for sops files. Aspect modules lack `inputs` in scope — `config._module.args.self.outPath` doesn't work either.
**Verify:** New aspects should never reference `inputs.self`. Use `../..` relative paths from the aspect file location.

---

## Identity & Configuration (Post-Migration)

### jvf.core.* is Single Source of Truth
**Lesson:** Never hardcode `default = "josevictor"` in username options. Use `default = config.jvf.core.username` instead.
**Context:** 57 modules previously hardcoded the username. The audit fixed this by making `jvf.core.username` the canonical source.
**Verify:** `grep -rn 'default = "josevictor"' modules/` should return 0 results.

### No specialArgs — Use _module.args or config.jvf.core.*
**Lesson:** specialArgs anti-pattern is BANNED. Pass values through:
- `config.jvf.core.username`, `config.jvf.core.host`, `config.jvf.core.os` for identity
- `{ _module.args.inputs = inputs; }` in host modules for inputs access
**Context:** Legacy code passed `{ os, username, host, system, inputs }` via specialArgs. This violated dendritic principles and caused maintenance issues.
**Verify:** `grep -rn 'specialArgs' modules/` should only return comments/docs.

### Host Configs Are Pure Enable-Lists
**Lesson:** Host config files should only contain: `jvf.core.*` identity, `jvf.<aspect>.enable` toggles, and `system.stateVersion`. Never add raw NixOS/Darwin config blocks.
**Context:** Host configs previously had raw networking, security.sudo, fonts.packages blocks. These were extracted to aspects.
**Verify:** `wc -l hosts/*/config.nix` should be <50 lines each.

---

## Verification

### Never Trust Subagent Success Claims
**Lesson:** Always run verification commands yourself after task completion. Subagents frequently claim success with incomplete/broken work.
**Context:** Automated checks pass but manual code review often reveals logic errors, missing edge cases, or incomplete implementations.
**Verify:** Run `nix flake check` and eval tests after EVERY task completion before proceeding.

### Darwin Configs Only Fully Validate on macOS
**Lesson:** `nix flake check` on Linux skips `darwinConfigurations` eval (incompatible system). Use `nix eval .#darwinConfigurations.<host>.options.<path>` for targeted Darwin option type-checks on Linux.
**Context:** Darwin eval verified via `nix eval` type probes. Structural errors may go undetected until macOS rebuild.
**Verify:** Always run both `nix eval .#darwinConfigurations...` AND `nix flake check` — they catch different classes of errors.

---

## NixOS Options

### Define Package Option Values in Config
**Lesson:** When a module builds a package and exposes it via an option, always set the option value in the config section.
**Context:** `programs-ck-search.nix` built `ckSearchPkg` but never assigned it to `jvf.programs.ck-search.package`, causing "option accessed but has no value" errors when other modules tried to use it.
**Verify:** Ensure modules set `cfg.package = lib.mkDefault builtPackage;` in their config section if other modules depend on the package option.

### Enable Options Must Be Set in Host Configs
**Lesson:** Aspects with enable options require explicit `enable = true;` in host configs for their config to take effect.
**Context:** `jvf.system.nixpkgs.enable` was missing from host config, so allowUnfree settings never applied, causing Steam build failure.
**Verify:** After adding an aspect to imports, check if it has required enable options that need setting in host config.

---

## Context Management

### Prune Aggressively During Refactors
**Lesson:** Large refactoring generates many tool outputs. Prune context after each wave/phase to avoid hitting limits.
**Context:** Nix evaluation outputs, file reads, and bash commands accumulate quickly during multi-wave refactors.
**Verify:** Use `distill` for key findings and `prune` for noise every 3-4 tasks.

---

## Nix String Indentation

- **Rule:** When generating config files (YAML, JSON) in Nix, use `pkgs.formats.*` instead of multi-line strings with `''`. Nix's `''` strings strip minimum indentation, breaking YAML structure.
- **Why:** Wasted 30+ minutes debugging YAML parsing errors caused by Nix string indentation stripping.
- **Check:** If generating structured config, verify output with `cat` after first test run.

---

## Runtime Path Resolution

- **Rule:** For flake templates needing runtime paths (like `$PWD`), use placeholder substitution (`@@PLACEHOLDER@@` + `sed`) at runtime rather than relying on `projectRoot` which resolves to Nix store paths.
- **Why:** `projectRoot = ./.` in flakes resolves to store path at eval time, not the actual working directory.
- **Check:** Test with `nix develop --impure --command bash -c 'echo $SANDBOX_STATE'` and verify paths point to working directory.

---

## Process-Compose Commands

- **Rule:** `process-compose up` uses `-f` for config file; `process-compose down/ps` use `-U -u <socket>` for Unix socket connection. Use `-D` (not `-d`) for detached mode.
- **Why:** Wrong flags cause "unknown shorthand flag" errors or connection failures.
- **Check:** Run `process-compose <cmd> --help` to verify correct flags before implementing.

---

## Nix Flake with Sockets

- **Rule:** When running `nix develop` multiple times in a directory with Unix sockets (`.sock` files) or special files, Nix will fail with "unsupported type". Clean state directory before re-evaluating flake.
- **Why:** Nix cannot handle socket files in flake source tree during evaluation.
- **Check:** If seeing "unsupported type" errors, run `rm -rf .sandbox-state` before `nix develop`.

---

## Nixpkgs Lib Functions

### pkgs.formats for Structured Config
**Lesson:** Use `pkgs.formats.json { }` (not `lib.formats` or `pkgs.lib.formats`) for generating structured config in NixOS modules.
**Context:** `lib.formats` is not available in module lib context; `formats` is an attribute of nixpkgs pkgs, not lib.
**Verify:** Test with `nix repl '<nixpkgs>'` then `:pkgs.formats.json { }` to confirm.

---

## Shell Script Builders

### writeShellApplication Runs ShellCheck
**Lesson:** `pkgs.writeShellApplication` runs shellcheck validation; use `pkgs.writeScriptBin` to skip validation for scripts with complex quoted text.
**Context:** RFC2119 text in prompt-enhancer contained quotes that caused shellcheck failures. writeScriptBin doesn't run shellcheck.
**Verify:** If script fails with "SC1078" or "SC1079" errors, switch to writeScriptBin.

---

## Module Coordination

### Coordinate Subsystem Ownership Between Modules
**Lesson:** When two aspect modules configure the same subsystem (e.g., sops), one must own the config and the other must only consume it. Never split `defaultSopsFile`/`age.keyFile` across modules.
**Context:** `system-security.nix` and `secrets-sops.nix` both touched sops config, causing "No key source configured" assertion. Fix: single owner for sops base config.
**Verify:** Before creating an aspect that uses sops/networking/etc, `grep -r` for existing config of that subsystem across all aspects.

### git add Before nix eval in Flakes
**Lesson:** Always `git add` new files before running `nix eval` or `nix flake check`. Flakes use pure evaluation — untracked files are invisible.
**Context:** Creating new aspect files without `git add` causes cryptic "file not found" errors during verification.
**Verify:** Run `git add modules/<category>/<name>.nix` immediately after creating the file, before any Nix command.

---

## Hardware Module Extraction

### Split Reusable Boot Config from Machine-Specific hardware.nix
**Lesson:** `hosts/<hostname>/hardware.nix` should only contain machine-specific UUIDs/partlabels/filesystems. Extract reusable patterns (kernel, grub, plymouth, btrfs) to `modules/hardware/*.nix` aspects.
**Context:** 150+ line hardware.nix monoliths mix reusable boot config with machine-specific UUIDs. Extract boot.nix, btrfs.nix aspects; hardware.nix becomes pure filesystem+swap definitions.
**Verify:** `wc -l hosts/*/hardware.nix` should be <50 lines after extraction.
