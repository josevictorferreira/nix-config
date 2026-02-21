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
