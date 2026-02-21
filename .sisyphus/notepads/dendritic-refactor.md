
## Task 1 Findings (2026-02-21)

### Patterns That Worked
1. **flake-parts.lib.mkFlake** - Clean migration from manual outputs
2. **import-tree with ./modules/flake** - Allows future auto-discovery while keeping legacy modules isolated
3. **perSystem for formatter** - Standard flake-parts pattern
4. **flake.lib for per-system outputs** - Using forAllSystems pattern inside flake attribute

### Gotchas Encountered
1. **Path depth in legacy modules** - When modules moved to `modules/legacy/_/`, relative imports like `../../../../lib/` needed updating to `../../../../../../lib/` (6 levels up instead of 4)
2. **infinite recursion with pkgs** - In modules that use `isDarwin` in top-level config branching, must use `system` specialArg instead of `pkgs.stdenv.isDarwin` to avoid infinite recursion
3. **Git staging** - All files must be staged in git before nix can see them in the store

### Key Files Modified
- `flake.nix` - Converted to flake-parts structure
- `modules/legacy/_/users/default.nix` - Changed `pkgs.stdenv.isDarwin` to use `system` specialArg
- `modules/legacy/_/programs/zsh/plugins/default.nix` - Fixed lib import path
- `modules/flake/default.nix` - Created empty flake-parts module directory
- `modules/core/options.nix` - Created for jvf.core.* options

### Verification Commands Used
```bash
nix flake check --show-trace
nix eval .#nixosConfigurations.nixos-desktop.config.system.build.toplevel.outPath
nix eval .#darwinConfigurations.macos-macbook.pkgs.stdenv.hostPlatform
nix eval .#formatter.x86_64-linux.outPath
```

## Task 2: Legacy Ignore Area - Learnings (2026-02-21)

### Key Insight
The `/_` path convention in import-tree is used to ignore directories. All legacy NixOS/Darwin modules are now under `modules/legacy/_/`.

### What Was Done
- Created `modules/legacy/_/` directory structure
- Moved all module directories (system, roles, users, hardware, services, programs, desktop, common) to the legacy area
- Updated flake.nix imports to reference new paths
- Updated hosts/nixos-desktop/config.nix hyprland import

### Verification
- `nix flake check --show-trace` passes
- All relative imports within modules remain functional

### Notes
- The modules were already moved in a previous commit (task 1)
- No module content was modified
- The path `/_` ensures import-tree won't auto-import these modules
