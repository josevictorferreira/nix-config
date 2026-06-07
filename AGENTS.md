# PROJECT KNOWLEDGE BASE

**Generated:** 2026-02-23
**Commit:** N/A (Dynamic)

## OVERVIEW
NixOS/Darwin unified workspace. Desktop-focused (Hyprland/macOS).
Stack: Nix flakes, SOPS (secrets), explicit module options (`jvf.*`), NO Home Manager.
Based on: KooL's NixOS-Hyprland.

## STRUCTURE
```
./
├── modules/
│   ├── hosts/               # Host configurations (single source of truth)
│   │   ├── nixos-desktop/
│   │   │   ├── default.nix  # Selector + identity + config (merged)
│   │   │   └── _/hardware.nix  # Machine-specific filesystems/UUIDs
│   │   └── macos-macbook/
│   │       └── default.nix  # Selector + identity + config (merged)
│   ├── programs/            # Per-program modules (each in own folder)
│   │   ├── kitty/
│   │   │   └── default.nix  # Dendritic module (future: + assets, secrets)
│   │   ├── neovim/
│   │   ├── git/
│   │   └── ... (24 programs)
│   ├── system/              # System-level config modules
│   │   ├── networking.nix
│   │   ├── audio.nix
│   │   └── ... (16 modules)
│   ├── services/            # System services
│   │   ├── docker.nix
│   │   └── ...
│   ├── roles/               # Import-closure bundles (pull deps transitively)
│   │   ├── desktop.nix
│   │   ├── development.nix
│   │   ├── gaming.nix
│   │   └── ... (14 roles)
│   ├── desktop/
│   │   └── hyprland/        # Hyprland desktop environment
│   │       ├── default.nix  # Main hyprland module
│   │       ├── ags.nix, rofi.nix, waybar.nix, ...
│   │       └── assets/      # Desktop config files (co-located)
│   │           ├── hypr/    # Hyprland configs
│   │           ├── rofi/    # Rofi configs + themes
│   │           ├── waybar/  # Waybar configs + styles
│   │           └── ...
│   ├── home/                # Home file materialization (jvf.home)
│   │   └── default.nix     # jvf.home option schema + activation scripts
│   ├── checks/              # Flake checks (eval + VM tests)
│   │   └── home.nix        # jvf.home eval guard + NixOS VM test
│   ├── hardware/            # Hardware-specific modules
│   │   ├── amd-gpu.nix
│   │   ├── bluetooth.nix
│   │   ├── boot.nix         # Kernel, grub, plymouth, binfmt
│   │   ├── btrfs.nix        # Btrfs autoScrub
│   │   └── ... (6 modules)
│   ├── ai-tools/            # AI tools DSL modules
│   │   ├── agents.nix, commands.nix, mcp.nix, ...
│   │   └── ... (6 modules)
│   ├── boot/                # Boot configuration
│   │   └── grub-theme.nix
│   ├── core/                # Core option definitions
│   │   ├── jvf.nix          # Main jvf options (dendritic)
│   │   └── _/options.nix    # NixOS options (excluded from import-tree)
│   ├── darwin/              # macOS-specific modules
│   │   └── defaults.nix
│   ├── secrets/             # Secrets management
│   │   └── sops.nix
│   ├── flake/               # Flake-parts configuration
│   │   └── default.nix
│   ├── overlays.nix         # Custom package overlays
│   ├── repositories.nix     # Nix repository config
│   ├── users.nix            # User definitions
│   └── wrappers.nix         # Wrapper scripts + PATH/env (config → jvf.home)
├── pkgs/                    # Custom packages overlay
├── secrets/                 # SOPS encrypted secrets
├── templates/               # Project scaffolds
├── flake.nix                # Entry point (single import-tree ./modules)
└── Makefile                 # Command runner
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **New Program** | `modules/programs/<name>/default.nix` | Own folder, dendritic exports |
| **New System Module** | `modules/system/<name>.nix` | Flat in system/ |
| **New Service** | `modules/services/<name>.nix` | Flat in services/ |
| **New Role** | `modules/roles/<name>.nix` | Feature bundles |
| **Desktop Configs** | `modules/desktop/hyprland/assets/` | Co-located static configs |
| **Hardware/Boot** | `modules/hardware/boot.nix` | Kernel, grub, plymouth, binfmt |
| **AI Agents** | `modules/ai-tools/*.nix` | 7 dendritic modules |
| **Home File Config** | `modules/home/default.nix` | `jvf.home.users.<u>.items`, `jvf.home.xdg.config.*` |
| **Home Checks** | `modules/checks/home.nix` | eval + VM integration tests |
| **Migrate Config to jvf.home** | See wrappers migration pattern | packages stay in wrappers; configs → jvf.home |
| **Overlays** | `modules/overlays.nix` | Custom packages |
| **New Machine** | `modules/hosts/<hostname>/default.nix` | Selector + identity + config merged |

## CONVENTIONS
- **Architecture**: Import = active. No `mkEnableOption` on leaf modules. Roles are import closures.
- **Identity**: `config.jvf.core.username` is the single source of truth for username. NEVER hardcode `"josevictor"` in module defaults.
- **specialArgs**: Only `inputs` passed via specialArgs. Identity (username/host/os) comes from `config.jvf.core.*`, set in host config files.
- **Naming**: Kebab-case files.
- **Imports**: Group top-level. Specific imports only (no `import ./dir`).
- **Platform**: Use `mkConfig { isDarwin }` pattern, not `pkgs.stdenv.isDarwin`.
- **Formatting**: `nixpkgs-fmt` (via `make format`).
- **Config Materialization**: Config files/dirs go to `jvf.home`, NOT wrappers. Wrappers only handles wrapper scripts, env vars, PATH symlinks.

** START IMPORTANT SECTION **
 Prioritize readability, API ergonomics, and maintainability.
- Prefer simple and elegant solutions over clever or complex ones.
- Optimize for code that is easy to understand and modify.
- Design APIs that are intuitive, consistent, and hard to misuse.
- Avoid unnecessary abstractions or premature optimization.
- When in doubt, choose clarity over brevity or performance.
** END IMPORTANT SECTION **

## DENDRITIC MODULE PATTERN

This project uses **flake-parts** with **dendritic** (branch-like) module organization:

- Each aspect file exports: `flake.modules.nixos.<name>` and `flake.modules.darwin.<name>`
- **Import = active** — no `mkEnableOption` on leaf modules. Importing enables them.
- Roles are import closures: `imports = with self.modules.nixos; [ prog-a prog-b ... ];`
- Host files (`modules/hosts/<name>/default.nix`) are single source of truth (selector + identity + config)
- Platform detection: Use `mkConfig { isDarwin }` pattern, not `pkgs.stdenv.isDarwin`
- Machine-specific hardware goes in `modules/hosts/<name>/_/hardware.nix` (excluded from import-tree)

### Adding New Leaf Module
```nix
# modules/programs/my-new-program/default.nix
{ ... }:
let
  mkConfig = { isDarwin }: { config, lib, pkgs, ... }: {
    options.jvf.programs.my-new.username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
    };
    config = { /* always active when imported */ };
  };
in
{
  flake.modules.nixos.programs-my-new = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-my-new = mkConfig { isDarwin = true; };
}
```

Then add to the appropriate **role** (not host):
```nix
# modules/roles/development.nix — imports pull in deps transitively
imports = with nixosAspects; [ programs-my-new ... ];
```

Or directly to host selector if not role-appropriate:
```nix
# modules/hosts/nixos-desktop/default.nix
(with self.modules.nixos; [ ... programs-my-new ... ])
```

### Managing Config Files (jvf.home)
New modules should use `jvf.home` for config file deployment:
```nix
# In your module's config section:
config = {
  # Simple file
  jvf.home.users.${cfg.username}.xdg.config."kitty/kitty.conf" = {
    kind = "file"; mode = "copy"; text = generatedConfig;
  };
  # Directory with preserve + postInstall
  jvf.home.users.${cfg.username}.items.".claude" = {
    kind = "dir"; mode = "copy"; source = configPkg;
    preserve = [ "transcripts" "history.jsonl" ];
    postInstall = ''cp "$TARGET_PATH/settings.json" "$HOME_DIR/.claude.json"'';
  };
};
```

## ANTI-PATTERNS (THIS PROJECT)
- **Home Manager**: BANNED. Use native NixOS/Darwin modules + `users.users`.
- **specialArgs for identity**: BANNED. Only `inputs` via specialArgs. Use `config.jvf.core.*` for username/host/os.
- **Hardcoded username**: BANNED. Use `config.jvf.core.username` as default in all module options.
- **Implicit Enable**: Modules activate by inclusion (import). No enable toggles on leaf modules.
- **Relative ../ imports**: Use absolute path from root for cross-module.
- **Old Module Style**: Don't create `modules/{programs,system,roles}/default.nix` aggregators
- **Config in wrappers**: BANNED. All modules use `jvf.home.users.<u>.xdg.config."<prog>/<file>"` for config file management. Wrappers only handles packages, wrapper scripts, and env vars.

## COMMANDS
```bash
make format       # REQUIRED before commit
make check        # Validate structure
make rebuild      # Apply config (auto-detect OS)
make update       # Update flake inputs
make clean        # GC
```

## NOTES
- `modules/ai-tools/` is a complex module with its own DSL.
- `roles` are import closures that pull in program/service/system aspects transitively.
- Hosts import roles; roles import leaf aspects. No enable toggles.
- `modules/home/default.nix` owns all home file/dir materialization. `modules/wrappers.nix` only handles wrapper scripts + packages.
- `modules/checks/home.nix` provides `jvf-home-eval` (pure eval) and `jvf-home-vm` (NixOS VM integration test covering copy, preserve, postInstall, and A→B config switch).

## HIERARCHY
Subdirectory AGENTS.md for complex modules:
- [modules/ai-tools/AGENTS.md](modules/ai-tools/AGENTS.md) — AI tools DSL
- [modules/desktop/hyprland/AGENTS.md](modules/desktop/hyprland/AGENTS.md) — Hyprland desktop
- No sub-AGENTS.md needed for home/ or checks/ (they're single files, not complex multi-module dirs)

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

### Nix String Indentation
**Lesson:** When generating config files (YAML, JSON) in Nix, use `pkgs.formats.*` instead of multi-line strings with `''`. Nix's `''` strings strip minimum indentation, breaking YAML structure.
**Context:** Wasted 30+ minutes debugging YAML parsing errors caused by Nix string indentation stripping.
**Verify:** If generating structured config, verify output with `cat` after first test run.

---
---
---
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

---

## Dendritic Module Imports

### Leaf Modules Must Not Import Other Leaf Modules
**Lesson:** In the dendritic pattern, leaf aspect modules must NEVER import other leaf modules via `imports = [ self.modules.nixos.other-leaf ];`. Only **roles** should compose leaf modules transitively. If leaf A imports leaf B, and a host imports both A and B (directly or via roles), the NixOS module system throws "option is already declared" because B's options get registered twice.
**Context:** Note: `wrappers.nix` and `home.nix` both define `jvf.home` options, but this is handled at the flake-parts level where both modules are imported by hosts. The key point: leaf modules should NOT import other leaf modules in their NixOS module `imports` list — let the host or roles handle transitive imports.
**Verify:** `grep -rn 'self\.modules\.\(nixos\|darwin\)\.' modules/programs/ modules/system/ modules/services/ modules/hardware/` — leaf modules should NEVER reference `self.modules.*` in their `imports` list. Only `modules/roles/*.nix` should.

### Conflict Detection Cannot Use Config Self-Reference
**Lesson:** When a translation layer sets `jvf.home.users.<u>.items` via `mkMerge`, you cannot detect conflicts by inspecting `config.jvf.home.users.<u>.items` from the same module — the translated items are already merged in, so you'd be checking against yourself. Use `builtins.tryEval` in a separate NixOS test evaluation instead.
**Context:** The wrappers→jvf.home translation layer needed to detect when a directly-migrated module and the legacy translation both write to the same path. Self-referencing `config.jvf.home` saw the translated items, making conflict detection impossible inline. Solution: conflict assertions deferred to test-time `tryEval`.
**Verify:** If adding translation/adapter layers between module systems, always test conflict detection in a separate eval context (e.g., `pkgs.runCommand` with `nix eval`), not inline assertions.

---

## Shell Safety in NixOS Activation Scripts

### Always Shell-Escape Nix Values in Bash Activation Scripts
**Lesson:** Any Nix string interpolated into bash activation scripts (especially file paths, user-provided values) must be wrapped with `lib.escapeShellArg`. Unescaped values with spaces, quotes, or special characters cause silent failures or security issues in activation scripts.
**Context:** `jvf.home` activation scripts interpolated `preserve` subpaths directly into bash `find` and `cp` commands. Paths with spaces would break. Fixed by wrapping all interpolated paths with `lib.escapeShellArg`.
**Verify:** After writing NixOS activation scripts, grep for `${}` interpolations inside bash strings and ensure each is wrapped with `lib.escapeShellArg` or equivalent quoting.

---

---

## jvf.home Subsystem

### Config Materialization Goes to jvf.home, Not Wrappers
**Lesson:** ALL modules MUST use `jvf.home.users.<u>.xdg.config.*` or `jvf.home.users.<u>.items.*` for config file/dir deployment. Wrappers only handles wrapper scripts, packages, and PATH symlinks.
**Context:** The jvf-home refactor (completed) moved all config materialization from wrappers to jvf.home. No translation layer exists — wrappers no longer accepts `configs`, `configPath`, `preserveFiles`, or `postInstall` options.
**Verify:** `grep -rn 'configs.*=' modules/programs/ modules/desktop/` should show only jvf.home patterns, not wrappers patterns.

### jvf.home Item API
**Lesson:** Items require `kind` ("file"/"dir"), optional `mode` ("copy"/"link"/"seed", default "copy"). Content: use `source` (path/derivation), `text` (string), or structured (`json`/`yaml`/`toml`/`ini` attrs). Dir items support `preserve` (list of subpaths) and `postInstall` (bash script with env vars: `TARGET_PATH`, `HOME_DIR`, `USER_NAME`, `GROUP_NAME`, `IS_DARWIN`, `BACKUP_DIR`).
**Context:** The API is defined in `modules/home/default.nix`. Sugar shortcuts: `jvf.home.files.*` → `~/*`, `jvf.home.xdg.config.*` → `~/.config/*`.
**Verify:** `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.home._compiled --show-trace` to inspect compiled items.

### Migration Complete — No Translation Layer
**Lesson:** All 27 modules have been migrated from wrappers configs to jvf.home. The wrappers translation layer has been removed. Wrappers options are now: `packages`, `command`, `env` only.
**Context:** Migration completed across 5 phases. wrappers.nix is now 219 lines (down from ~400+), handling only wrapper scripts and packages.
**Verify:** `grep -rn 'jvf.wrappers.*configs' modules/` should return 0 results. `wc -l modules/wrappers.nix` should be ~219.

---

## Nix Derivation Merging

### symlinkJoin Over runCommand for Merging Symlink Trees
**Lesson:** When merging multiple derivations that contain symlinks (e.g., `linkFarm` outputs), use `pkgs.symlinkJoin` instead of `pkgs.runCommand` with `cp -rL`. The latter fails in the sandbox because symlink targets aren't declared as build dependencies.
**Context:** `cp -rL` inside `runCommand` can't follow symlinks to store paths not in the derivation's direct inputs. `symlinkJoin` properly declares all paths as dependencies.
**Verify:** If merging config derivations, prefer `symlinkJoin { name = ...; paths = [ a b ]; }` over `runCommand` with `cp`.

### pkgs.runCommand Requires Exactly 3 Arguments
**Lesson:** `pkgs.runCommand` signature is `name: attrset: script:`. Passing only 2 args (`name: script:`) returns a partially applied function, NOT a derivation. The empty attrset `{}` is mandatory.
**Context:** Subagent omitted the `{}` — eval produced cryptic type errors ("is not of type 'null or absolute path or package'") far from the actual bug.
### pkgs.formats.ini Doesn't Support Booleans
**Lesson:** `pkgs.formats.ini` fails on Boolean values. Use custom generator: `toIni = attrs: lib.concatStringsSep "\n" (lib.mapAttrsToList (n: v: "${n}=${if lib.isBool v then (if v then "true" else "false") else toString v}") attrs);`
**Context:** btop config has `theme_background = true` which caused `expected a set but found a Boolean` error. INI format serializer doesn't handle Bool type.
**Verify:** Test with `nix-instantiate --eval` before using in production. Check config attrs for Booleans with `lib.filterAttrs (n: v: lib.isBool v) attrs`.

### Check for Partial Migrations Before Starting Work
**Lesson:** Before migrating a module to jvf.home, check if other modules in the same directory have partial migrations that might cause "dynamic attribute already defined" errors. Restore corrupted files immediately via `git checkout HEAD -- <file>`.
**Context:** qt5ct.nix and qt6ct.nix had BOTH old `configs` AND new `jvf.home` items from previous failed migrations, causing repeated build failures. Had to restore multiple times.
**Verify:** `git diff modules/<category>/` before starting. Look for files with both `configs =` and `jvf.home` in same module.

### Verify Incrementally During Batch Migrations
**Lesson:** After completing each module migration in a batch, run targeted `nix eval` on that module's config before proceeding to the next. Don't wait until all 5 modules are done to verify.
**Context:** Batch 1C built all 5 modules before verifying. When btop failed, had to debug in isolation while other modules were already correct. Incremental verification catches errors faster.
**Verify:** After each migration: `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.home._compiled.users.<user>.items` and check for errors.

### Use lib.mkMerge for Multiple jvf.home.items Paths
**Lesson:** When setting multiple `jvf.home.users.${cfg.username}.items."path"` in same module, wrap each in `lib.mkMerge [{ items."path1" = ...; } { items."path2" = ...; }]`. Direct assignments cause "dynamic attribute already defined" errors.
**Context:** qt5ct/qt6ct needed 3 INI files each. Single `config = { items."a" = ...; items."b" = ...; }` fails. lib.mkMerge solves it.
**Verify:** `nix eval .#nixosConfigurations.<host>` — if "dynamic attribute already defined" appears, switch to mkMerge.

### Use Bash/Cat for Complex Nix Rewrites
**Lesson:** After 2+ failed `edit` tool attempts on Nix files, switch to `bash/cat` full rewrite. Incremental edits often corrupt brace structure.
**Context:** kvantum.nix took 6 edit iterations, each corrupting braces. Full rewrite via bash/cat fixed immediately.
**Verify:** If file has syntax errors after edit, check brace count matches (`grep -c '{'` vs `grep -c '}'`).

### Group jvf.* Attributes for Statix
**Lesson:** When a module sets multiple `jvf.programs.*`, `jvf.wrappers.*`, `jvf.home.*`, group under single `jvf = { ... }` block. Statix flags split assignments.
**Context:** k9s had 3 separate jvf.* blocks. Statix warning: "The key jvf is first assigned here ... repeated here".
**Verify:** Run `nix build .#checks.x86_64-linux.statix` — if W10/W11 warnings about repeated jvf, consolidate.

### Verify with nix eval Early
**Lesson:** Run `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel` after each module migration, not just at end. Catches dynamic attribute conflicts immediately.
**Context:** Assumed `nix flake check` would catch all errors. Dynamic attribute conflicts only appear during NixOS module eval.
**Verify:** After each migration: `nix eval .#nixosConfigurations.nixos-desktop` — should return derivation path.



### Use Python Instead of Edit/Write Tool for Full Rewrites
**Lesson:** When rewriting a Nix file entirely (not just editing a few lines), use Python to write the file directly: `python3 -c "open(f, 'w').write(content)"`. The edit/write tools corrupt content with hash-ID prefixes on this system.
**Context:** Edit and write tools repeatedly produced files with content like `#PH|#Aspect: programs-opencode` instead of proper nix syntax. Required 4+ restore-from-git cycles to recover.
**Verify:** After write, run `nix-instantiate --parse <file>` to confirm syntax is valid before eval.

### Check git status for Unrelated File Corruption
**Lesson:** When debugging VM test failures, always run `git status --short` first. Unrelated files may have been corrupted in a previous session, blocking builds.
**Context:** hermes-agent/default.nix was pre-corrupted. VM test failed with syntax error on that file, wasting time debugging my changes before discovering the real cause.
**Verify:** `git diff <suspect-file>` shows unexpected changes → `git checkout HEAD -- <suspect-file>` to restore.

### Read Tool Shows Hash IDs, Not Actual Content
**Lesson:** The `read` tool prefix characters (like `#PH|#`, `#PJ|#`) are for navigation only — they don't appear in actual files. When `read` output looks corrupted but bash shows correct content, trust bash.
**Context:** `read` showed hash prefixes on every line making content look corrupted, but `head file` showed proper nix code. Tool output metadata confused debugging.
**Verify:** `head -5 <file>` shows actual content. `nix-instantiate --parse <file>` confirms valid syntax.
---

## Config Layout Migration Patterns

### Check Both Directory and Prefix Nesting Patterns
**Lesson:** When flattening config directories, programs use two patterns: (1) **directory entries** where `name == programName` (e.g., hypr's `{"hypr" = derivation;}`), and (2) **prefixed file entries** where `name` starts with `programName/` (e.g., swaync's `{"swaync/config.json" = file;}`). Both need different flattening logic.
**Context:** Initial fix handled only directory-style nesting. swaync's prefix-style entries silently double-nested because they fell through to the default `linkFarm` case.
**Verify:** When migrating config layouts, `grep` for config key patterns: both exact `programName` matches and `programName/` prefixed keys.

---

## wrappers → jvf.home Migration Recipes

### Simple configs (static dir) → jvf.home dir item
**Lesson:** When `configs = { "name" = ./assets/name; }`, replace with `jvf.home.users.<u>.items.".config/name" = { kind = "dir"; mode = "copy"; source = ./assets/name/.; };`. Remove `configs` from wrappers. Keep `packages` in wrappers if present. If no packages, remove wrappers block entirely.
**Context:** Batch 1A migration pattern for 6 modules (xfce4, wlogout, wallust, thunar, etc). Trivial — single source path, no generation.
**Verify:** After migration, `grep 'configs' <file>` returns 0. `grep 'jvf.home' <file>` shows the new item.

### Re-Read After Structural Edits
**Lesson:** After range replacements that change brace/bracket structure, re-read the file immediately to verify correctness before running any Nix evaluation.
**Context:** Replacing lines 115-128 in rofi.nix (removing `configs` + adding `jvf.home`) caused a missing closing brace. The edit tool reported success but the file was malformed.
**Verify:** After any edit that adds/removes `{`, `}`, `(`, `)`, check `grep -c '{'` vs `grep -c '}'` — counts must match.

### Note Pre-Existing Failures, Don't Investigate
**Lesson:** When `make check` shows failures that are unrelated to your changes (statix warnings in untouched files, VM test failures from stale eval cache), note them as pre-existing and move on.
**Context:** Session spent 10+ min verifying statix warnings in `ai-tools/_/commands/implementation/do.nix` were pre-existing. The error message itself says "pre-existing" yet still pulled attention.
**Verify:** Check `git diff` — if file wasn't touched in this session, its check failures are pre-existing. If error doesn't match file content, re-run `make check` before investigating (stale eval cache can produce false errors).

### Pre-check Batch Migration Status to Avoid Wasted Delegation
**Lesson:** Before delegating or implementing a batch migration (2+ modules), do a quick grep to check which modules are already migrated. Modules with `configs` still present in wrappers block need migration; modules without are already done.
**Context:** In Phase 2, 2 of 5 modules (ags, rofi) were already migrated. Agents correctly detected this but delegation was wasted overhead. A single `grep -l 'configs.*=' modules/desktop/hyprland/{ags,rofi,hypr,swaync,gtk3}.nix` would have identified the already-done modules upfront.

### Nix Migration Delegation Has High Failure Rate
**Lesson:** For batch Nix module migrations following a known recipe (configs → linkFarm → jvf.home items), prefer direct implementation with Python write over delegation. Agents corrupt/delete files at ~75% rate for this task type.
**Context:** Phase 3 delegated 4 modules; 3/4 agents corrupted files (1 deleted entire directory). Recovery took ~45 min — exceeding estimated ~40 min for manual implementation of all 4.
**Verify:** If 2+ agents fail during batch Nix migration, switch to manual implementation for remaining modules.

### Check Module Import Chain Before Debugging Missing Output
**Lesson:** When a jvf.home item doesn't appear in `_compiled` output, verify the module is actually imported by a host/role before investigating the module code itself.
**Context:** Droid's `.factory` item was absent from `_compiled` — spent time debugging before realizing droid isn't imported by any host/role (pre-existing orphan module).
**Verify:** `grep -r '<module-name>' modules/roles/ modules/hosts/` — if no hits, the module is orphaned and its items won't appear in compiled output.

## Adding Skills with Bundled Resources to ai-tools

### Use _body.md and builtins.readFile for Skill Files with Frontmatter
**Lesson:** When adding a skill from an external SKILL.md with YAML frontmatter, pre-extract the body with `awk 'BEGIN{sep=0} /^---$/{sep++; next} sep>=2{print}' SKILL.md > _body.md` and load via `builtins.readFile`. Place all bundled files (scripts, agents, assets, eval-viewer) in a co-located `_/<skill-name>/` directory (prefixed with `_/` so import-tree ignores it).
**Context:** Nix lacks clean YAML frontmatter stripping — pre-extraction avoids complex string manipulation at eval time. Files in `_/<name>/` won't be auto-discovered by import-tree.
**Verify:** `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.programs.opencode.skills.<name>.name` returns the skill name.

### Map Non-Standard Skill Directories to scripts/ Attribute
**Lesson:** The skill system only materializes `scripts/` and `references/` subdirectories. Map agents/, eval-viewer/, assets/ into the `scripts` attribute with path separators in keys (e.g., `scripts."agents/grader.md"`), then use `builtins.replaceStrings` to adjust file path references in the prompt from `agents/grader.md` to `scripts/agents/grader.md`.
**Context:** `mkSingleSkillConfigs` writes scripts as `skills/<name>/scripts/<key>` — keys with `/` create nested directories. References stay as `references/<key>.md`.
**Verify:** Check prompt references match: `grep 'agents/' <skill-nix-file>` should show `scripts/agents/` prefix.

## Hyprland & Desktop Integrations

### Auto-Closing Scratchpads on App Spawn
**Lesson:** When an application running inside a Hyprland special workspace (scratchpad) spawns an external GUI window (like opening a file in a player or browser), intercept the opener command to toggle the special workspace off.
**Context:** By default, new windows spawned from a special workspace open in the regular workspace underneath, leaving the user staring at the still-open scratchpad while the newly opened file is hidden behind it.
**Verify:** Prefix the app's internal opener commands with a conditional Hyprland dispatch: `hyprctl activewindow | grep -q "class: <expected-class>" && hyprctl dispatch togglespecialworkspace <name>; <original_cmd>`. This ensures it only auto-closes when actually running as a scratchpad.

### XDG Portal UseIn Restriction on Hyprland
**Lesson:** `xdg-desktop-portal-gtk` declares `UseIn=gnome` in its `.portal` file, so it silently refuses to load on Hyprland (`XDG_CURRENT_DESKTOP=Hyprland`). This means the `Settings` interface (used by Chromium browsers for `color-scheme`) is unavailable. Fix: `overrideAttrs` to patch `UseIn=gnome;Hyprland` + `lib.mkForce` on `extraPortals` to prevent duplicate collision (Hyprland NixOS module also adds unpatched GTK portal).
**Context:** Brave couldn't detect system theme because the portal lacked Settings interface. No error or warning — just silent absence. Required `gdbus introspect` to diagnose.
**Verify:** `gdbus introspect --session --dest org.freedesktop.portal.Desktop --object-path /org/freedesktop/portal/desktop` should list `org.freedesktop.portal.Settings` after rebuild + `systemctl --user restart xdg-desktop-portal`.

### sed Config Editing Must Verify Match
**Lesson:** When using `sed -i` to edit config files in activation/switcher scripts, always verify the sed pattern matches the actual file format first. `sed` exits 0 on no-match, producing false-positive "ok" logs. Read the target file to confirm key format (spaces around `=`, quotes around values, etc.) before writing the pattern.
**Context:** btop.conf uses `color_theme = "tokyonight-night"` (spaces + quotes) but sed pattern `^color_theme=.*` expected `color_theme=` (no spaces). Script logged success but never changed the value.
**Verify:** After writing sed-based config editing, test with `sed -n '/<pattern>/p' <config-file>` to confirm the pattern actually matches before relying on it.
