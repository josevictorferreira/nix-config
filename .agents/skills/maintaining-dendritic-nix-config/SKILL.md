---
name: "maintaining-dendritic-nix-config"
description: >
  Specialized knowledge for maintaining this specific dendritic Nix flake repository
  (NixOS/Darwin unified workspace, jvf.* namespace, flake-parts + import-tree).
  Use when: editing any module under modules/, adding new programs/system/roles,
  modifying host configs, working with jvf.home or wrappers, or evaluating/rebuilding
  the flake. Covers dendritic patterns, anti-patterns, and project-specific conventions.
  
allowed-tools:
  - Read*
  - Grep*
  - Glob*
  - Write*
  - Bash*
compatibility: opencode
---

# Maintaining Dendritic Nix Config

You are working on a **dendritic Nix flake repository**: a unified NixOS/Darwin
workspace using flake-parts with recursive auto-discovery via `import-tree`.
The project namespace is `jvf.*`. Understanding these rules prevents costly mistakes.

## Architecture at a Glance

- **Import = active**: Leaf modules have NO `mkEnableOption`. Importing enables them.
- **Roles compose**: Only `modules/roles/*.nix` should import other leaf modules.
  Leaf modules must NEVER import other leaf modules.
- **Host files** (`modules/hosts/<name>/default.nix`) are identity + data only.
  They import roles; roles import leaf aspects transitively.
- **Single import-tree call**: `flake.nix` uses `(inputs.import-tree ./modules)` once.
  All `.nix` files under `modules/` are auto-discovered; paths containing `/_` are excluded.
- **Export pattern**: Every aspect file exports BOTH:
  `flake.modules.nixos.<name>` AND `flake.modules.darwin.<name>`.

## Critical Anti-Patterns (NEVER DO)

1. **Never hardcode `"josevictor"`** — use `config.jvf.core.username` as default.
2. **No specialArgs for identity** — only `inputs` via specialArgs.
   Identity comes from `config.jvf.core.{username,host,os}`.
3. **No `pkgs.stdenv.isDarwin`** — use `mkConfig { isDarwin }` parameter pattern.
4. **No `inputs.self`** in aspects — use relative paths (e.g., `../../secrets/...`).
5. **No `enable` toggles on leaf modules** — import = active. Strip `mkEnableOption`
   from programs/system/services/hardware modules.
6. **Leaf modules must NOT import other leaf modules** — causes
   "option already declared" errors. Only roles compose.
7. **Never put config in wrappers** — wrappers only handles packages, PATH, env vars.
   All config files go to `jvf.home.users.<u>.xdg.config.*` or `items.*`.
8. **No `../` relative imports across modules** — use absolute paths from repo root.
9. **No `lib.formats`** — use `pkgs.formats.json { }` (formats is on pkgs, not lib).

## jvf.home (Config Materialization)

All config files/dirs MUST use `jvf.home`. Wrappers no longer accepts `configs`.

```nix
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
```

**Important:**
- Use `lib.mkMerge` when setting multiple `items."path"` in the same module.
- Always wrap interpolated paths in bash activation scripts with `lib.escapeShellArg`.
- Dir items support `preserve` (subpaths kept across rebuilds) and `postInstall`
  (bash with env vars: `TARGET_PATH`, `HOME_DIR`, `USER_NAME`, `GROUP_NAME`,
  `IS_DARWIN`, `BACKUP_DIR`).

## jvf.wrappers (CLI Commands on PATH)

Wrappers expose executables on the user PATH. Each
`jvf.wrappers.users.${cfg.username}.programs.<key>` with a non-null `command`
produces EXACTLY ONE binary named `<key>` (a `writeShellScriptBin` that execs
`${command} "$@"`). To expose N command names you need N program keys.

```nix
# Three commands -> three keys, all pointing at one core script + subcommand
jvf.wrappers.users.${cfg.username}.programs = {
  "myapp-status".command = "${core}/bin/myapp-core status";
  "myapp-toggle".command = "${core}/bin/myapp-core toggle";
  "myapp-reset".command  = "${core}/bin/myapp-core reset";
};
```

Build the core script with `pkgs.writeShellScriptBin` (NOT
`writeShellApplication`) when it contains shell heredocs / many quotes —
shellcheck-free avoids spurious failures. Add runtime deps (e.g. `libnotify`
for `notify-send`) by prepending them to `PATH` inside the script.

## Adding New Modules

| Task | Location | Pattern |
|------|----------|---------|
| New Program | `modules/programs/<name>/default.nix` | Own folder, dendritic exports |
| New System Module | `modules/system/<name>.nix` | Flat file |
| New Service | `modules/services/<name>.nix` | Flat file |
| New Role | `modules/roles/<name>.nix` | Import closure |
| New Host | `modules/hosts/<hostname>/default.nix` | Selector + identity + config |
| Hardware (machine-specific) | `modules/hosts/<hostname>/_/hardware.nix` | Excluded from import-tree |

### New Leaf Module Template

```nix
{ ... }:
let
  mkConfig = { isDarwin }: { config, lib, pkgs, ... }:
  let cfg = config.jvf.programs.my-new; in {
    options.jvf.programs.my-new.username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
    };
    config = {
      # Always active when imported
      jvf.home.users.${cfg.username}.xdg.config."my-new/config.conf" = { ... };
    };
  };
in {
  flake.modules.nixos.programs-my-new = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-my-new = mkConfig { isDarwin = true; };
}
```

## Verification & Workflow

- **Always** run `make format` before committing.
- **Always** `git add` new files before `nix eval` or `nix flake check`
  (flakes use pure eval; untracked files are invisible).
- After module changes, verify with:
  ```bash
  nix eval .#nixosConfigurations.nixos-desktop.config.system.build.toplevel
  nix flake check
  ```
- Darwin configs only fully validate on macOS. On Linux, use:
  ```bash
  nix eval .#darwinConfigurations.<host>.options.<path>
  ```
- When wrapping values that might conflict with `qemu-vm.nix` (e.g., `gfxmodeBios`),
  use `lib.mkDefault`.

## Sub-Feature Enables Are Allowed

Some modules keep `mkEnableOption` for **sub-features** within an active module:
`git.lfs.enable`, `tmux.tmuxp.enable`, `weechat.matrix.enable`.
These are intentional exceptions — the module is active by inclusion;
the sub-feature is opt-in within it.

## Nix String / Config Generation

- Use `pkgs.formats.json { }`, `pkgs.formats.yaml { }`, `pkgs.formats.toml { }`
  for structured config. Do NOT use multi-line `''` strings for YAML/JSON/TOML —
  Nix indentation stripping corrupts structure.
- `pkgs.formats.ini` does NOT support booleans. Use a custom generator if needed.
- `pkgs.writeShellApplication` runs shellcheck; use `pkgs.writeScriptBin`
  to skip validation for scripts with complex quoted text.
- `pkgs.runCommand` requires exactly 3 args: `name: {}: script:`.
- `pkgs.symlinkJoin` (not `runCommand` with `cp -rL`) for merging symlink trees.

## Common Error Signatures & Fixes

| Error | Likely Cause | Fix |
|-------|-------------|-----|
| `attribute 'nixos' missing` | Wrong export: `{ nixos = ... }` instead of `{ flake.modules.nixos... }` | Use correct export pattern |
| `option is already declared` | Leaf module imports another leaf module | Remove import; let roles compose |
| `No key source configured` (sops) | Two modules set sops base config | Single owner for sops config |
| `conflicting definition values` (VM) | Boot/grub setting clashes with qemu-vm.nix | Wrap with `lib.mkDefault` |
| `ln: failed to create symbolic link '.../xdg-desktop-portal-gtk.service': File exists` | External module (e.g., Hyprland) also contributes portal to `extraPortals` | Use `lib.mkForce` on `extraPortals` to override entire list |
| `dynamic attribute already defined` | Multiple `items."path"` in same module | Use `lib.mkMerge` |
| `expected a set but found a Boolean` (INI) | `pkgs.formats.ini` with bool values | Custom generator |

## Before You Start Editing

1. Read the full reference rules: `references/dendritic-rules.md`
2. Check `modules/ai-tools/AGENTS.md` for ai-tools DSL specifics
3. Check `modules/desktop/hyprland/AGENTS.md` for desktop-specific rules
4. Verify with `nix flake check` after every change

Remember: **Import = active. Simple over clever. Read before coding.**
