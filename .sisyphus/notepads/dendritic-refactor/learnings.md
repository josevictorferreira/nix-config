# Dendritic Refactor — Learnings & Decisions

## Task 3: specialArgs → jvf.core.* options

### Decision: Keep `system` specialArg for 4 modules
Cannot use pkgs.stdenv.isDarwin in:
- `imports` blocks (eval'd before pkgs available)
- Top-level `lib.optionalAttrs` in config (causes pkgs→config→pkgs cycle)
Affected: users/default.nix, users/wrappers.nix, roles/gaming.nix, roles/network-storage.nix

### Decision: Use pkgs.stdenv.isDarwin only in mkIf-guarded config
Safe pattern: `isDarwin = pkgs.stdenv.isDarwin;` then use in package lists inside config block.
Applied to: roles/monitoring.nix, roles/privacy.nix

### Issue: Parallel task conflicts on flake.nix
flake.nix was modified by multiple parallel tasks simultaneously. Required re-applying edits.
Mitigation: coordinate flake.nix edits sequentially, or use atomic commits per task.

### Issue: flake-parts + import-tree migration (parallel task)
Another task migrated flake.nix to flake-parts with import-tree. Module paths changed from
`./modules/{users,hardware,...}/` to `./modules/legacy/_/{users,hardware,...}/`.
Task 3 changes had to account for both old and new path structures.

### Pattern: jvf.core.* options as specialArgs replacement
Works well for simple string values (username, host, os).
Host configs set: `jvf.core = { inherit username host os; };`
Modules read: `config.jvf.core.username` instead of function arg `username`.

## Task 4: nixos-desktop dendritic host aspect

### Architecture decision
- Created `modules/hosts/nixos-desktop.nix` as flake-parts module
- Added `(inputs.import-tree ./modules/hosts)` to flake.nix imports
- Removed inline `nixosConfigurations` and `nixosModule` from flake.nix `flake` block
- Removed `systems.nixos` from flake.nix (no longer referenced)

### Key: relative paths in dendritic module
- Module at `modules/hosts/nixos-desktop.nix` uses `../../` relative paths to reach:
  - `../../modules/core/options.nix`
  - `../../modules/legacy/_/...`
  - `../../hosts/nixos-desktop/config.nix`
  - `../../lib`
- These resolve correctly because nix evaluates relative to the file's location in the store

### Compatibility: specialArgs still passed
- `hosts/nixos-desktop/config.nix` function args: `{ host, inputs, username, os, ... }`
- These come from specialArgs (transitional, until config.nix migrated to use only jvf.core.*)

## Task 8: secrets-sops aspect (2026-02-21)

- `modules/aspects/` directory needed `import-tree` entry in flake.nix imports (added between flake and hosts)
- New files must be `git add`ed before nix can see them (dirty tree warning, but store path missing without staging)
- Aspect defines `flake.modules.nixos.secrets-sops` and `flake.modules.darwin.secrets-sops` — these are flake-parts module attrsets available for host wiring
- Duplicate sops imports (aspect + direct in host file) are safe — NixOS merges modules idempotently
- The aspect pattern is clean: single file per cross-cutting concern, both platforms handled

## Task 9: perSystem overlays aspect

### Pattern: perSystem pkgs with darwin detection
```nix
perSystem = { system, ... }:
  let isDarwin = builtins.match ".*-darwin" system != null;
  in { _module.args.pkgs = import (if isDarwin then ... else ...) { ... }; };
```

### Gotcha: import-tree + flake.modules merging
- Multiple aspects defining `flake.modules.{nixos,darwin}.*` as raw attrsets causes merge conflict
- flake-parts error: "No option has been declared for this flake output attribute"
- Workaround: import aspects explicitly instead of via import-tree until resolved
- Fix needed: either use flake-parts `flakeModules` option, declare a custom option with `lib.mkOption { type = lib.types.attrsOf ... }`, or consolidate `flake.modules` into single module

### Decision: explicit import over import-tree
- Used `./modules/aspects/overlays.nix` directly in imports list
- Other aspects (tasks 6-8) need flake.modules merge fix before import-tree can cover full aspects/

## Task 6: core-jvf aspect (2026-02-21)

- `flake.modules` is NOT a built-in flake-parts option. Must declare it in `modules/flake/default.nix` with `lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw)` for proper merging across multiple aspect files.
- Darwin needs `{ nixpkgs.hostPlatform = system; }` in modules list when legacy modules that use `pkgs` are imported (e.g. programs/btop uses `pkgs.stdenv.isDarwin`).
- Pattern for host files: `{ inputs, self, ... }:` — `self` provides `self.modules.{nixos,darwin}.*`.
- Legacy user modules (default.nix, wrappers.nix, repositories.nix) all require `system` specialArg for isDarwin check.
- hardware/default.nix excluded from Darwin aspect (NixOS-only: amd-gpu, bluetooth, logitech, openrgb).

## Task 7: desktop-hyprland + darwin-defaults aspects (2026-02-21)

### Key Decisions
- `desktop-hyprland` aspect only imports the legacy hyprland module tree; host config still sets `jvf.desktop.hyprland.enable = true`
- `darwin-defaults` aspect extracts `system.defaults` + `system.keyboard` from host config into reusable module
- Removed direct hyprland import from `hosts/nixos-desktop/config.nix` (moved to aspect)
- Removed `system.defaults`/`system.keyboard` from `hosts/macos-macbook/config.nix` (moved to aspect)

### Critical Fix: flake.modules merging via import-tree
- Prior task (8/9) only imported `overlays.nix` explicitly in flake.nix, not all aspects
- **Changed flake.nix to use `(inputs.import-tree ./modules/aspects)`** instead of individual imports
- This works because `modules/flake/default.nix` declares `flake.modules` as `attrsOf (attrsOf unspecified)` — a proper module option that deep-merges
- All aspect files can now set `flake.modules.nixos.<name>` and `flake.modules.darwin.<name>` independently
- `warning: unknown flake output 'modules'` is expected (flake-parts exposes it as custom output)

### Host Cleanup
- `hosts/nixos-desktop/config.nix`: removed `inputs`/`self` args (no longer needed after hyprland import moved to aspect)
- `hosts/macos-macbook/config.nix`: removed `inputs`/`self` args, system.defaults, system.keyboard

### Verification
- `nix flake check` passes
- `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.desktop.hyprland.enable` → `true`
- `nix eval .#darwinConfigurations.macos-macbook.config.system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled` → `false`
- `nix eval .#darwinConfigurations.macos-macbook.config.system.keyboard` → keyboard remapping active
