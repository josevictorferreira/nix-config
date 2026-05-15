# Dendritic Nix Config — Comprehensive Reference Rules

This is the exhaustive rule set for maintaining this repository. Refer to this when the quick-reference in the main skill prompt is insufficient.

---

## 1. Dendritic Module Pattern

### Import-Tree Discovery
- `flake.nix` uses **exactly one** `(inputs.import-tree ./modules)` call.
- import-tree recursively discovers ALL `.nix` files under its root.
- Paths containing `/_` are excluded from auto-import.
- Use `/_` for helper modules that shouldn't be flake-parts modules (e.g., `modules/core/_/options.nix`, `modules/hosts/nixos-desktop/_/hardware.nix`).

### Export Pattern
Every aspect file MUST export as:
```nix
{
  flake.modules.nixos.name = ...;
  flake.modules.darwin.name = ...;
}
```
NOT `{ nixos = ...; darwin = ...; }` — this causes "attribute 'nixos' missing".

### Per-Module Folder Organization
- **Programs**: `modules/programs/<name>/default.nix` (own folder, allows co-located assets/secrets)
- **System/Services/Roles/Hardware**: flat `.nix` files in category dirs
- **No `modules/{programs,system,roles}/default.nix` aggregators**

### Adding New Leaf Module
```nix
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

### Roles Are Import Closures
Roles use `imports = with nixosAspects; [ prog-a prog-b ... ];` to pull in deps transitively.
Hosts import roles; roles import aspects — no `enable` toggles anywhere.

Roles can reference `self.modules.nixos.*` in their `imports` without infinite recursion.

### Leaf Modules Must Not Import Other Leaf Modules
In the dendritic pattern, leaf aspect modules must NEVER import other leaf modules via `imports = [ self.modules.nixos.other-leaf ];`. Only **roles** should compose leaf modules transitively. If leaf A imports leaf B, and a host imports both A and B, the module system throws "option is already declared" because B's options get registered twice.

### Platform Detection
Use `mkConfig { isDarwin }` pattern, NOT `pkgs.stdenv.isDarwin`.

---

## 2. Identity & Configuration

### jvf.core.* is Single Source of Truth
- `config.jvf.core.username` is the canonical username.
- NEVER hardcode `default = "josevictor"` in username options.
- Use `default = config.jvf.core.username` instead.
- Identity (username/host/os) comes from `config.jvf.core.*`, set in host config files.

### No specialArgs
- specialArgs anti-pattern is BANNED.
- Only `inputs` passed via specialArgs.
- Pass values through `config.jvf.core.username`, `config.jvf.core.host`, `config.jvf.core.os`.
- Or use `{ _module.args.inputs = inputs; }` in host modules for inputs access.

### Host Configs Are Pure Identity + Data
Host config files should only contain:
1. `jvf.core.*` identity
2. Role/aspect data options (NOT enable toggles)
3. `system.stateVersion`

Never add raw NixOS/Darwin config blocks. Host identity sections should be <30 lines.

---

## 3. Config Materialization (jvf.home)

### All Config Goes to jvf.home
ALL modules MUST use `jvf.home.users.<u>.xdg.config.*` or `jvf.home.users.<u>.items.*` for config file/dir deployment. Wrappers only handles wrapper scripts, packages, and PATH symlinks.

### jvf.home Item API
- Items require `kind` ("file"/"dir"), optional `mode` ("copy"/"link"/"seed", default "copy").
- Content: use `source` (path/derivation), `text` (string), or structured (`json`/`yaml`/`toml`/`ini` attrs).
- Dir items support `preserve` (list of subpaths) and `postInstall` (bash script with env vars: `TARGET_PATH`, `HOME_DIR`, `USER_NAME`, `GROUP_NAME`, `IS_DARWIN`, `BACKUP_DIR`).
- Sugar shortcuts: `jvf.home.files.*` → `~/*`, `jvf.home.xdg.config.*` → `~/.config/*`.

### Migration Complete
- All 27 modules migrated from wrappers configs to jvf.home.
- The wrappers translation layer has been removed.
- Wrappers options are now: `packages`, `command`, `env` only.

### lib.mkMerge for Multiple Items
When setting multiple `jvf.home.users.${cfg.username}.items."path"` in same module, wrap each in `lib.mkMerge [{ items."path1" = ...; } { items."path2" = ...; }]`. Direct assignments cause "dynamic attribute already defined" errors.

### Shell-Escape in Activation Scripts
Any Nix string interpolated into bash activation scripts must be wrapped with `lib.escapeShellArg`. Unescaped values with spaces, quotes, or special characters cause silent failures or security issues.

---

## 4. Nix Coding Patterns

### pkgs.formats for Structured Config
Use `pkgs.formats.json { }`, `pkgs.formats.yaml { }`, `pkgs.formats.toml { }` for generating structured config. NOT multi-line `''` strings — Nix's `''` strings strip minimum indentation, breaking YAML/JSON structure.

`lib.formats` is NOT available in module lib context; `formats` is an attribute of nixpkgs pkgs.

### pkgs.formats.ini Doesn't Support Booleans
Use custom generator:
```nix
toIni = attrs: lib.concatStringsSep "\n" (lib.mapAttrsToList (n: v: "${n}=${if lib.isBool v then (if v then "true" else "false") else toString v}") attrs);
```

### Shell Script Builders
- `pkgs.writeShellApplication` runs shellcheck validation.
- Use `pkgs.writeScriptBin` to skip validation for scripts with complex quoted text.

### pkgs.runCommand Requires Exactly 3 Arguments
Signature: `name: attrset: script:`. Passing only 2 args returns a partially applied function, NOT a derivation. The empty attrset `{}` is mandatory.

### symlinkJoin Over runCommand
When merging multiple derivations containing symlinks, use `pkgs.symlinkJoin` instead of `pkgs.runCommand` with `cp -rL`. The latter fails in sandbox because symlink targets aren't declared as build dependencies.

### Dynamic Attribute Access
Interpolated attrpaths like `colors."color${i}"` are invalid Nix syntax. Use `lib.getAttr "color${toString i}" colors` instead.

### Group jvf.* Attributes for Statix
When a module sets multiple `jvf.programs.*`, `jvf.wrappers.*`, `jvf.home.*`, group under single `jvf = { ... }` block. Statix flags split assignments.

### Nix String Indentation
When generating config files in Nix, use `pkgs.formats.*` instead of multi-line strings with `''`.

---

## 5. Verification & Commands

### Commands
```bash
make format       # REQUIRED before commit
make check        # Validate structure
make rebuild      # Apply config (auto-detect OS)
make update       # Update flake inputs
make clean        # GC
```

### git add Before nix eval in Flakes
Always `git add` new files before running `nix eval` or `nix flake check`. Flakes use pure evaluation — untracked files are invisible.

### Darwin Configs Only Fully Validate on macOS
`nix flake check` on Linux skips `darwinConfigurations` eval. Use `nix eval .#darwinConfigurations.<host>.options.<path>` for targeted Darwin option type-checks on Linux.

### Verify Incrementally During Batch Work
After completing each module change, run targeted `nix eval` before proceeding to the next. Don't wait until all are done.

### Use lib.mkDefault for VM Conflicts
When defining values for hardware/boot settings that might conflict with `qemu-vm.nix` overrides during `nixos-rebuild build-vm` (like `gfxmodeBios`), always wrap them in `lib.mkDefault`.

### Never Trust Success Claims
Always run verification commands yourself after task completion. Automated checks pass but manual code review often reveals logic errors.

---

## 6. Module Coordination

### Coordinate Subsystem Ownership
When two aspect modules configure the same subsystem (e.g., sops), one must own the config and the other must only consume it. Never split `defaultSopsFile`/`age.keyFile` across modules.

### Define Package Option Values in Config
When a module builds a package and exposes it via an option, always set the option value in the config section. If other modules depend on the package option, ensure `cfg.package = lib.mkDefault builtPackage;`.

### Self-Referencing Assertions After Enable Removal
When stripping `mkEnableOption` from a module, check for assertions that reference the module's own `.enable` option. These become self-referencing errors since the option no longer exists.

### Check Module Import Chain Before Debugging
When a jvf.home item doesn't appear in `_compiled` output, verify the module is actually imported by a host/role before investigating the module code itself.

---

## 7. Config Layout & File Operations

### Check Both Directory and Prefix Nesting Patterns
When flattening config directories, programs use two patterns:
1. **directory entries** where `name == programName` (e.g., hypr's `{"hypr" = derivation;}`)
2. **prefixed file entries** where `name` starts with `programName/` (e.g., swaync's `{"swaync/config.json" = file;}`)

Both need different flattening logic.

### Use Python Instead of Edit/Write Tool for Full Rewrites
When rewriting a Nix file entirely (not just editing a few lines), use Python to write the file directly: `python3 -c "open(f, 'w').write(content)"`. The edit/write tools may corrupt content with hash-ID prefixes on this system.

### Re-Read After Structural Edits
After range replacements that change brace/bracket structure, re-read the file immediately to verify correctness before running any Nix evaluation.

---

## 8. Hardware Module Extraction

### Split Reusable Boot Config from Machine-Specific hardware.nix
`hosts/<hostname>/hardware.nix` should only contain machine-specific UUIDs/partlabels/filesystems. Extract reusable patterns (kernel, grub, plymouth, btrfs) to `modules/hardware/*.nix` aspects. hardware.nix becomes pure filesystem+swap definitions (<50 lines).

### hardware.nix Must Be in `/_`
Plain NixOS hardware modules (containing `modulesPath` in `_module.args`) MUST be placed in `_/hardware.nix` under the host directory. import-tree treats all `.nix` files as flake-parts modules — a plain NixOS module causes infinite recursion during eval.

---

## 9. Adding Skills with Bundled Resources

### Use _body.md and builtins.readFile for Skill Files with Frontmatter
When adding a skill from an external SKILL.md with YAML frontmatter, pre-extract the body with `awk` and load via `builtins.readFile`. Place bundled files in `_/<skill-name>/` (prefixed with `_/` so import-tree ignores it).

### Map Non-Standard Skill Directories to scripts/ Attribute
The skill system materializes `scripts/` and `references/` subdirectories. Map agents/, eval-viewer/, assets/ into the `scripts` attribute with path separators in keys, then use `builtins.replaceStrings` to adjust file path references.

---

## 10. Subagent Code Generation Pitfalls

### Subagents Create Variables But Don't Wire Them
After subagent work on Nix modules, ALWAYS verify that newly created `let` bindings are actually used in the `config` output.

### Embedded `\n` Strings Are Syntax Errors
Subagents often emit `\n` as literal strings instead of actual newlines. Ensure multiline strings use proper `''` syntax or actual line breaks.

### Partial Migrations
Before migrating a module, check if other modules in the same directory have partial migrations that might cause "dynamic attribute already defined" errors. Restore corrupted files via `git checkout HEAD -- <file>`.

### Nix Migration Delegation Has High Failure Rate
For batch Nix module migrations following a known recipe, prefer direct implementation with Python write over delegation. Subagents corrupt/delete files at high rate for this task type.

---

## Key Principles Summary

1. **Import = active** — no mkEnableOption on leaf modules.
2. **Simple over clever** — prioritize readability, API ergonomics, maintainability.
3. **jvf.core.* is truth** — never hardcode identity.
4. **Config to jvf.home** — wrappers only for packages/PATH/env.
5. **Roles compose, leaves don't** — leaf modules never import other leaves.
6. **Verify everything** — run checks yourself, never trust claimed success.
7. **git add before nix eval** — pure evaluation ignores untracked files.
8. **make format before commit** — formatting is mandatory.
