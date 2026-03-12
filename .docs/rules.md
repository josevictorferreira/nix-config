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

### Host Configs Are Pure Identity + Data
**Lesson:** Host config files should only contain: `jvf.core.*` identity, role/aspect data options (NOT enable toggles), and `system.stateVersion`. Never add raw NixOS/Darwin config blocks.
**Context:** P0 switched to inclusion-based architecture — modules are active when imported, no `enable = true` toggles needed. P7 merged selector+config into single files.
**Verify:** Host identity sections in `modules/hosts/*/default.nix` should be <30 lines. `grep -c 'enable' modules/hosts/*/default.nix` should return 0.

### Python Transitive Dependency Overrides
**Lesson:** Use `lib.composeExtensions attrs.packageOverrides myFixes` to ensure your overrides apply *after* internal package overrides (e.g., in `ceph`).
**Context:** Ceph pins `cryptography` via `packageOverrides`; standard overlays are wiped out unless explicitly composed after Ceph's internal ones.
**Verify:** Check if `doCheck = false` or similar attributes survive by evaluating the target package's final attributes.

### Sphinx 9.1.0 Downgrade on Python 3.11
**Lesson:** If Sphinx 9 (Python 3.12+) is forced on Python 3.11, downgrade to 8.1.3, add `psuper.roman` to `propagatedBuildInputs`, and set `dontCheckRuntimeDeps = true`.
**Context:** Sphinx 9.1.0 uses Python 3.12 syntax (`type _PARSER_SETUP = ...`) which causes SyntaxErrors during evaluation on Python 3.11.
**Verify:** Run `nix-build -A python311Packages.sphinx` and confirm it unpacks and evaluates without SyntaxError.

### Forcibly Bypassing Documentation Generation
**Lesson:** To stop a Python package from running `sphinx-build`, filter out `sphinxHook` AND `sphinx` from `nativeBuildInputs` and clear `postBuild`.
**Context:** Many packages (like `typeguard`) ignore `dontBuildDocs = true` if the hook is present or if they manually invoke the binary in `postBuild`.
**Verify:** Check the build log to ensure `sphinx-build` is never invoked and `sphinx_autodoc_typehints` is not imported.

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

### Modules Active by Inclusion (Post-P0)
**Lesson:** Leaf modules no longer have `mkEnableOption`. Importing an aspect = activating it. To disable, remove it from the host selector's import list (or from the role that imports it).
**Context:** P0 stripped `mkEnableOption` from ~65 leaf modules. The old pattern required both importing AND setting `enable = true` — a violation of the dendritic "import = active" principle.
**Verify:** `grep -rn 'mkEnableOption' modules/programs/ modules/system/ modules/hardware/ modules/services/` should return 0 results (except ai-tools DSL internals and sub-feature enables like `lfs.enable`, `matrix.enable`).

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


---

## Refactoring Decisions

### Assess Monolith Cohesion Before Splitting
**Lesson:** Before splitting a large file, check if `isDarwin` (or other parameters) are legitimately used throughout. A 1000+ line file with cohesive logic (one program's config, mostly data declarations) is NOT automatically a split candidate.
**Context:** `wrappers.nix`, `opencode/default.nix`, `zsh/default.nix` were flagged as monoliths but are cohesive single-purpose files. Splitting would create cross-file dependencies for no readability gain.
**Verify:** `grep isDarwin <file>` — if used in multiple places with real branching, the `mkConfig { isDarwin }` pattern is justified.

---

## Inclusion-Based Architecture (P0)

### Roles Are Import Closures, Not Enable Bundles
**Lesson:** Role modules use `imports = with nixosAspects; [ ... ];` to pull in program/service/system aspects transitively. Hosts import roles, roles import aspects — no `enable` toggles anywhere.
**Context:** The old pattern had roles setting `jvf.programs.X.enable = true` which required both import AND enable. The new pattern: importing a role = importing all its dependency aspects. Roles accept `{ self, ... }` at the top level to access `self.modules.nixos.*`.
**Verify:** `grep -c 'mkEnableOption\|mkIf cfg.enable' modules/roles/*.nix` should return 0 for all files.

### Roles Can Import self.modules.nixos.* Without Infinite Recursion
**Lesson:** Flake-parts modules can reference `self.modules.nixos.*` in their NixOS module's `imports` list without causing infinite recursion. The flake-parts layer evaluates lazily — module DEFINITIONS happen at flake-parts time, but `imports` resolution happens at NixOS module evaluation time.
**Context:** Confirmed by real-world repos (drupol/infra, Doc-Steve/dendritic-design-with-flake-parts) and Oracle analysis. Pattern: `{ self, ... }: let nixosAspects = self.modules.nixos; in { flake.modules.nixos.role-X = { imports = with nixosAspects; [ ... ]; }; }`.
**Verify:** `nix flake check` — if roles cause recursion, this will fail immediately.

### Sub-Feature Enables Are Intentional Exceptions
**Lesson:** Some modules intentionally keep `mkEnableOption` for **sub-features** within an already-active module. Examples: `git.lfs.enable`, `tmux.tmuxp.enable`, `weechat.matrix.enable`, `gemini.antigravity.enable`. These are NOT violations of the inclusion pattern.
**Context:** Sub-features toggle optional heavyweight dependencies or protocol support within an active module. The module itself is active by inclusion; the sub-feature is opt-in within it.
**Verify:** Sub-feature enables should be nested under the module's option namespace, not at the top level.

### ai-tools DSL Enables Are Intentional Exceptions
**Lesson:** The 6 ai-tools modules (`agents.nix`, `commands.nix`, `mcp.nix`, etc.) keep `mkEnableOption` for per-agent, per-command, per-server toggles. These are **DSL-internal** controls, not module-level enables.
**Context:** ai-tools is a complex DSL where each agent/command/server is independently toggleable. Path: `jvf.aiTools.*`. This is a data-driven pattern, not the old import+enable pattern.
**Verify:** ai-tools enables should all be under `jvf.aiTools.*`, never `jvf.programs.*` or `jvf.system.*`.

### Host Selectors Import Roles + Infra, Not Leaf Aspects
**Lesson:** After P0, host files (`modules/hosts/<hostname>/default.nix`) import: (1) core infra aspects (locale, security, nixpkgs, nix-daemon), (2) hardware aspects, (3) roles, (4) ai-tools, (5) desktop sub-aspects. They do NOT import individual program/service/system aspects — those come transitively via roles.
**Context:** nixos-desktop went from 133 → 146 lines (merged selector+config), macos-macbook from 109+19 → 91 lines. Programs come via roles.
**Verify:** `grep -c 'programs-' modules/hosts/nixos-desktop/default.nix` should return 0 (programs come via roles).

### Host Consolidation: Single Directory Per Host (P7)
**Lesson:** Each host lives in `modules/hosts/<hostname>/default.nix` — selector + identity + config merged into one file. Machine-specific hardware goes in `modules/hosts/<hostname>/_/hardware.nix` (the `/_` prefix excludes it from import-tree auto-discovery).
**Context:** The old two-location pattern had `modules/hosts/<name>.nix` (selector) + `hosts/<name>/config.nix` (identity). Merging eliminates cross-file coordination and the top-level `hosts/` directory.
**Verify:** `ls modules/hosts/*/default.nix` should list all hosts. `ls modules/hosts/*/_/hardware.nix` for machine-specific hardware. No top-level `hosts/` directory should exist.

### hardware.nix Must Be in `/_` to Avoid import-tree
**Lesson:** Plain NixOS hardware modules (containing `modulesPath` in `_module.args`) MUST be placed in `_/hardware.nix` under the host directory. import-tree treats all `.nix` files as flake-parts modules — a plain NixOS module causes infinite recursion during eval.
**Context:** First P7 attempt placed `hardware.nix` directly in `modules/hosts/nixos-desktop/` — import-tree picked it up, tried to eval as flake-parts module, and hit infinite recursion from `modulesPath`. Moving to `_/hardware.nix` fixed it.
**Verify:** `find modules/hosts -name 'hardware.nix' -not -path '*/_/*'` should return 0 results.

### Verify Flake Input Names When Merging Host Files
**Lesson:** When merging selector + config files, verify that flake input references match `flake.nix` input names exactly. Subagents may use wrong names (e.g., `inputs.nix-darwin` vs `inputs.darwin`).
**Context:** P7 merge created `inputs.nix-darwin.lib.darwinSystem` but the flake input is named `darwin`. Darwin configs are skipped on Linux `nix flake check`, so this wasn't caught automatically.
**Verify:** `grep -rn 'inputs\.' modules/hosts/*/default.nix` — cross-reference every input name against `flake.nix`.

### Self-Referencing Assertions After Enable Removal
**Lesson:** When stripping `mkEnableOption` from a module, check for assertions that reference the module's own `.enable` option. These become self-referencing errors since the option no longer exists.
**Context:** `zsh/default.nix` had `assertion = config.jvf.programs.zsh.enable -> pkgs ? zsh;` — after removing the enable option, this caused an eval error. Fixed to `assertion = pkgs ? zsh;`.
**Verify:** After removing `mkEnableOption`, grep the same file for `config.jvf.<module>.enable` references.

---

## Subagent Code Generation (Nix)

### Subagents Create Variables But Don't Wire Them
**Lesson:** After subagent work on Nix modules, ALWAYS verify that newly created `let` bindings are actually used in the `config` output. Subagents frequently define helper variables (`overrides`, `baseSettings`, `generatedX`) but forget to reference them.
**Context:** Ghostty adapter: subagent created `themeOverrides`, `baseSettings`, `paletteLines` but left `settings = defaultSettings` unchanged — theme variables never used.
**Verify:** After subagent Nix work, grep for each new `let` binding name in the `config =` section.

### Embedded `\n` Strings Are Syntax Errors
**Lesson:** Subagents often emit `\n` as literal strings instead of actual newlines in Nix code. These cause parse errors. When editing Nix, ensure multiline strings use proper `''` syntax or actual line breaks, not escaped `\n`.
**Context:** theme.nix had `\"color${toString i}\"` with embedded `\n` chars, causing LSP errors like "unexpected text".
**Verify:** After subagent edits to Nix files, run `lsp_diagnostics` and grep for `\\n` in string contexts.

### Dynamic Attribute Access Requires `lib.getAttr`
**Lesson:** Interpolated attrpaths like `colors.\"color${i}\"` are invalid Nix syntax. Use `lib.getAttr "color${toString i}" colors` instead for dynamic key access.
**Context:** Ghostty palette generation tried `config.jvf.theme.colors.\"color${toString i}\"` which caused multiple LSP errors.
**Verify:** When generating dynamic attribute access, use `lib.getAttr` or `builtins.getAttr`, not escaped quotes.

---

## Virtual Machine VM Conflicts

### mkDefault for VM conflicting configurations
**Lesson:** When defining values for hardware or boot settings that might conflict with `qemu-vm.nix` overrides during `nixos-rebuild build-vm` (like `gfxmodeBios`), always wrap them in `lib.mkDefault`.
**Context:** Standard `boot.loader.grub` settings often conflict with Nixpkgs' QEMU VM profile, preventing the VM build from evaluating.
**Verify:** Try evaluating `.system.build.vm` for the host and ensure no "conflicting definition values" errors appear.
