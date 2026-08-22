# Fix Statix Lint Warnings - Implementation Plan

**Generated:** 2026-02-25  
**Total Warnings:** 5 distinct types across ~50+ occurrences

---

## Executive Summary

This document provides a structured plan to fix all statix lint warnings in the Nix codebase. Warnings are organized by severity and fix complexity into three implementation phases.

**Warning Type Summary:**

| Code | Type | Count | Difficulty | Fix Pattern |
|------|------|-------|------------|-------------|
| W10 | Empty pattern | ~25 | Easy | `{ ... }:` → `_:` |
| W04 | Assignment vs inherit | ~12 | Medium | `x = cfg.x;` → `inherit (cfg) x;` |
| W08 | Useless parens | ~6 | Easy | `(expr)` → `expr` |
| W20 | Repeated keys | ~4 | Medium | Merge attrset paths |
| W02 | Empty let | ~1 | Easy | Remove empty block |

---

## Phase 1: Quick Wins (W10 + W08 + W02)

*Estimated time: 30 minutes*  
*Risk: Very Low - Simple pattern replacements*

### 1.1 W10 - Empty Pattern Warnings (~25 occurrences)

**Problem:** Function arguments use `{ ... }:` or `{ }:` when no parameters are accessed.

**Fix Pattern:**
```nix
# BEFORE
{ ... }:
{ }:

# AFTER
_:
```

**Files to Fix:**
1. `./modules/desktop/hyprland/wallust.nix:3`
2. `./modules/roles/designing.nix:3`
3. `./modules/programs/neovim/default.nix:5`
4. `./modules/hosts/macos-macbook/default.nix:67`
5. `./modules/ai-tools/agents.nix:4` + `1238`
6. `./modules/desktop/hyprland/qt5ct.nix:3`
7. `./modules/system/logind.nix:5`
8. `./modules/programs/k9s/_/settings.nix:3`
9. `./modules/roles/local-ai.nix:4`
10. `./modules/system/power-management.nix:5`
11. `./modules/programs/opencode/config/plugins.nix:2`
12. `./modules/ai-tools/skills.nix:4`
13. `./modules/system/environment.nix:4`
14. `./modules/programs/btop/default.nix:5`
15. `./modules/programs/claudecode/_/router-config.nix:3`
16. `./modules/programs/alacritty/default.nix:5`
17. `./modules/desktop/hyprland/kvantum.nix:3`
18. `./modules/programs/droid/default.nix:2`
19. `./modules/hardware/logitech.nix:4`
20. `./modules/programs/gemini/default.nix:5`
21. `./modules/desktop/hyprland/ags.nix:3`
22. `./modules/system/base-programs.nix:5` + `8`
23. `./modules/roles/privacy.nix:5`
24. `./modules/programs/ck-search/default.nix:1`
25. `./modules/programs/git/default.nix:5`

**Research Reference:**
- Statix lint: `empty_pattern` - https://github.com/oppiliappan/statix
- Nix manual on function arguments: https://nix.dev/tutorials/nix-language

---

### 1.2 W08 - Useless Parentheses (~6 occurrences)

**Problem:** Unnecessary parentheses around expressions in bindings.

**Fix Pattern:**
```nix
# BEFORE
config = (
  {
    # config content
  }
);

# AFTER
config = {
  # config content
};
```

**Files to Fix:**
1. `./modules/system/logind.nix:54-67` - `config = (...)`
2. `./modules/system/power-management.nix:81-103` - `config = (...)`
3. `./modules/programs/btop/default.nix:136-151` - Nested parens around attrset
4. `./modules/system/base-programs.nix:20-34` - `config = (...)`
5. `./modules/programs/git/default.nix:215-267` - `flake.modules.nixos.git = (...)`

**Research Reference:**
- Statix lint: `useless_parens` - https://github.com/oppiliappan/statix

---

### 1.3 W02 - Useless Let-in Expression (1 occurrence)

**Problem:** Empty `let...in` block with no bindings.

**File:** `./modules/system/base-programs.nix:16-35`

**Fix Pattern:**
```nix
# BEFORE
let in
{
  config = ...;
}

# AFTER
{
  config = ...;
}
```

---

## Phase 2: Inherit Conversions (W04)

*Estimated time: 45 minutes*  
*Risk: Low - Syntax transformation, verify no side effects*

### 2.1 W04 - Assignment Instead of Inherit (~12 occurrences)

**Problem:** Using assignment `x = source.x;` instead of `inherit (source) x;`

**Fix Pattern:**
```nix
# BEFORE
let
  agents = config.jvf.programs.opencode.agents;
  commands = config.jvf.programs.opencode.commands;
in

# AFTER  
let
  inherit (config.jvf.programs.opencode) agents commands;
in
```

**Files to Fix:**

1. **./modules/hosts/macos-macbook/default.nix:18-19**
   ```nix
   # BEFORE
   lib = pkgs.lib;
   inherit pkgs system;
   
   # AFTER
   inherit (pkgs) lib;
   inherit pkgs system;
   ```

2. **./modules/roles/ai-development.nix:50-53, 93-96**
   ```nix
   # BEFORE
   agents = config.jvf.programs.opencode.agents;
   commands = config.jvf.programs.opencode.commands;
   skills = config.jvf.programs.opencode.skills;
   mcps = config.jvf.programs.claudecode.mcps;
   
   # AFTER
   inherit (config.jvf.programs.opencode) agents commands skills;
   inherit (config.jvf.programs.claudecode) mcps;
   ```

3. **./modules/system/power-management.nix:98**
   ```nix
   # BEFORE
   cpuFreqGovernor = cfg.cpuFreqGovernor;
   
   # AFTER
   inherit (cfg) cpuFreqGovernor;
   ```

4. **./modules/programs/gemini/options.nix:52**
   ```nix
   # BEFORE
   type = json.type;
   
   # AFTER
   inherit (json) type;
   ```

5. **./modules/programs/claudecode/options.nix:44, 49**
   ```nix
   # BEFORE (both lines)
   type = json.type;
   
   # AFTER (consolidate if in same scope)
   inherit (json) type;
   ```

**Research Reference:**
- Statix lint: `manual_inherit_from` - https://github.com/oppiliappan/statix
- Nix `inherit` expression: https://nixos.org/manual/nix/stable/language/constructs.html#inheriting-attributes

---

## Phase 3: Attrset Restructuring (W20)

*Estimated time: 30 minutes*  
*Risk: Medium - Restructuring config, needs careful testing*

### 3.1 W20 - Repeated Keys in Attribute Sets (~4 occurrences)

**Problem:** Multiple `programs.x.y = ...;` patterns should be merged.

**Fix Pattern:**
```nix
# BEFORE
programs.nm-applet.indicator = true;
programs.mtr.enable = true;
programs.dconf.enable = true;

# AFTER
programs = {
  nm-applet.indicator = true;
  mtr.enable = true;
  dconf.enable = true;
};
```

**Files to Fix:**

1. **./templates/frontend-bun-vite/flake.nix:63, 103, 139**
   ```nix
   # BEFORE
   packages.default = pkgs.stdenv.mkDerivation { ... };
   packages.build-push = pkgs.writeShellApplication { ... };
   packages.deploy = pkgs.writeShellApplication { ... };
   
   # AFTER
   packages = {
     default = pkgs.stdenv.mkDerivation { ... };
     build-push = pkgs.writeShellApplication { ... };
     deploy = pkgs.writeShellApplication { ... };
   };
   ```

2. **./modules/system/base-programs.nix:28-30**
   ```nix
   # BEFORE
   programs.nm-applet.indicator = true;
   programs.mtr.enable = true;
   programs.dconf.enable = true;
   
   # AFTER
   programs = {
     nm-applet.indicator = true;
     mtr.enable = true;
     dconf.enable = true;
   };
   ```

**Research Reference:**
- Statix lint: `repeated_keys` - https://github.com/oppiliappan/statix
- Nix attrset syntax: https://nix.dev/tutorials/nix-language#attribute-set

---

## Implementation Checklist

### Phase 1: Quick Wins
- [ ] Fix W10 - Empty patterns (25 files)
- [ ] Fix W08 - Useless parens (5 files)  
- [ ] Fix W02 - Empty let (1 file)
- [ ] Run `nix flake check` to verify
- [ ] Run `statix check .` to confirm fixes

### Phase 2: Inherit Conversions
- [ ] Fix W04 - Assignment vs inherit (5 files, 12 occurrences)
- [ ] Run `nix flake check` to verify
- [ ] Run `statix check .` to confirm fixes

### Phase 3: Attrset Restructuring
- [ ] Fix W20 - Repeated keys (2 files)
- [ ] Run `nix flake check` to verify
- [ ] Run `statix check .` to confirm all warnings resolved

---

## Verification Commands

```bash
# Check current status
nix run nixpkgs#statix check .

# After each phase, verify Nix eval still works
nix flake check --no-build

# Full rebuild test (optional)
make rebuild
```

---

## Automation Options

Statix provides `statix fix` command for automatic fixes:

```bash
# Dry run to see what would change
nix run nixpkgs#statix fix --dry-run .

# Apply fixes automatically (review carefully)
nix run nixpkgs#statix fix .

# Note: Some fixes (like W20 attrset restructuring) may need manual adjustment
```

**Recommendation:** Run `statix fix --dry-run` first, then manually apply fixes using this plan as reference for cleaner git history.

---

## Notes & Edge Cases

1. **Line numbers may shift** as files are edited - always re-run `statix check` between phases
2. **W10 at line 1238** in `ai-tools/agents.nix` is inside a comment block - verify before fixing
3. **W20 fixes** require testing as they restructure config output
4. Consider adding `statix.toml` to disable specific lints if any are intentional:
   ```toml
   disabled = ["some_lint_name"]
   ```
