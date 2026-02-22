# Dendritic Module Migration — Notepad

## Task 1: users/default.nix → modules/aspects/users.nix ✅

### Pattern Established
- Shared options extracted into `mkUsersOption` function, imported by both platform modules
- No platform detection needed — dendritic pattern inherently separates platforms
- Host files must explicitly add new aspect to their module lists
- `core-jvf.nix` must have legacy import removed to avoid duplicate option definitions

### Gotchas
- New files must be `git add`ed before `nix eval` — flakes use pure evaluation
- `with self.modules.nixos;` in host files means the module name must match the attribute name in `flake.modules.nixos.<name>`

### Remaining Legacy User Modules
- `users/repositories.nix` — still in core-jvf imports
- `users/wrappers.nix` — still in core-jvf imports

## Task 2: Wrappers Migration (2026-02-21)

**Status:** COMPLETE

**Approach:** Parameterized `mkWrappersConfig { isDarwin }` — single implementation, platform branching via closure parameter. Shared options via `mkWrappersOption` imported by both platforms.

**Key insight:** Legacy used `system` specialArg for isDarwin check to avoid infinite recursion with `pkgs.stdenv.isDarwin` in top-level config branching. Dendritic approach eliminates this entirely by hardcoding isDarwin per platform module.

**Files:** aspects/wrappers.nix created, core-jvf.nix updated, both host selectors updated.
