# Dendritic Architecture Audit — Full Analysis & Improvement Proposals

**Date**: 2026-02-23
**Branch**: feature/dendritic-config
**Sources**: dendrix.oeiuwq.com, Doc-Steve/dendritic-design-with-flake-parts, codebase analysis

---

## 1. Current State vs Dendritic Spec

| Dendritic Principle | Our Status | Gap Severity |
|---|---|---|
| Enable by **inclusion**, not options | ❌ Every module has `mkEnableOption` | **Critical** |
| Hosts import only desired aspects | ❌ Host selectors list ALL 95+ modules | **Critical** |
| Feature-centric naming | ⚠️ Category-centric (`programs-kitty`, `system-audio`) | Medium |
| Feature closures (everything together) | ⚠️ Mixed — roles bundle enables, but don't own deps | Medium |
| Minimal flake.nix | ❌ Templates defined inline in flake.nix | Low |
| No specialArgs | ✅ Only `inputs` passed | Compliant |
| import-tree for all discovery | ✅ Single call | Compliant |
| `flake.modules.<class>.<aspect>` exports | ✅ Consistent across all 88 modules | Compliant |

---

## 2. Dead Code & Unused Modules

### 2a. Never-Enabled System Modules (12 of 16)

These are **imported** in the host selector but **never** have `enable = true` set anywhere:

| Module | Option Namespace | Status |
|---|---|---|
| `system/audio.nix` | `jvf.system.audio` | **Dead** — guarded by mkIf, never triggered |
| `system/base-programs.nix` | `jvf.system.basePrograms` | **Dead** |
| `system/base-services.nix` | `jvf.system.baseServices` | **Dead** |
| `system/display.nix` | `jvf.system.display` | **Dead** |
| `system/environment.nix` | `jvf.system.environment` | **Dead** |
| `system/firewall.nix` | `jvf.system.firewall` | **Dead** |
| `system/flatpak.nix` | `jvf.system.flatpak` | **Dead** |
| `system/logind.nix` | `jvf.system.logind` | **Dead** |
| `system/networking.nix` | `jvf.system.networking` | **Dead** |
| `system/power-management.nix` | `jvf.system.powerManagement` | **Dead** |
| `system/virtualization.nix` | `jvf.system.virtualization` | **Dead** |
| `system/xdg.nix` | `jvf.system.xdg` | **Dead** |

Only 4 are enabled: `locale`, `nixDaemon`, `nixpkgs`, `security`.

### 2b. Empty/Useless Modules

- **`ai-tools/default.nix`**: Has `jvf.aiTools.enable` option but config block is `{ }` — does nothing. Sub-aspects ignore it entirely.
- **`boot/grub-theme.nix`**: No options, no enable guard — just imports a nixosModule. Hardcoded to x86_64-linux.
- **`darwin/defaults.nix`**: No enable guard, always active when imported. Not using mkConfig pattern.

### 2c. Unnecessary isDarwin Boilerplate

9 programs receive `isDarwin` via mkConfig but **never branch on it** — identical code generates separate nixos + darwin modules pointlessly:

`alacritty`, `cursor`, `easyeffects`, `kitty`, `mistral-vibe`, `tmux`, `weechat`, `ck-search`, `k9s`

### 2d. Two-Layer Host Config Redundancy

Current flow: `modules/hosts/nixos-desktop.nix` (imports ALL 95+ aspects) → `hosts/nixos-desktop/config.nix` (enables subset via options). This is anti-dendritic — should be a single concise selector.

---

## 3. Structural Issues

### 3a. Monolithic wrappers.nix (~450 lines)

Handles 5 concerns in one file: config file generation, atomic swap with backup, file preservation, wrapper scripts, per-user activation. Should be split.

### 3b. Oversized Program Modules

- `opencode/default.nix`: **1,101 lines**
- `zsh/default.nix`: **1,025 lines**

These need splitting into sub-aspects.

### 3c. Hardcoded Values

- `desktop/hyprland/default.nix`: GTK bookmarks with workspace-specific paths (agrosmart, valoris, homelab, ComfyUI)
- `hosts/nixos-desktop/config.nix`: Raw `networking.interfaces.enp4s0.*` static IP config

---

## 4. Ranked Improvement Proposals

### 🔴 P0: Flip to Inclusion-Based Architecture (HIGH IMPACT)

**Problem**: Every module has `mkEnableOption` + host imports ALL 95 modules + config enables a subset. This is the inverse of dendritic.

**Target**:
```nix
# modules/hosts/nixos-desktop.nix — BEFORE (125 lines)
modules = with self.modules.nixos; [
  programs-kitty programs-zsh programs-git  # ...95 more
];

# AFTER (~15 lines)
modules = with self.modules.nixos; [
  role-desktop role-development role-ai-development role-gaming
  role-media role-privacy role-ops
  hardware-boot hardware-btrfs hardware-amd-gpu hardware-bluetooth
  system-locale system-security system-nixpkgs system-nix-daemon
];
```

**How**: Roles become **import closures** — they `imports = [...]` their dependencies instead of setting `enable = true`. Programs/services lose `enable` options, keeping only configuration options (ports, settings, paths).

**Migration**:
1. Pick one role (e.g., `development`). Convert it from "enable toggler" to "import closure"
2. Remove `enable` from all programs it depends on
3. Remove those programs from host selector — role handles it
4. Compare `system.build.toplevel` before/after to verify identical output
5. Repeat for all 12 roles
6. Host selectors shrink from 95 lines to ~15

### 🔴 P1: Delete/Activate Dead System Modules (HIGH IMPACT)

12 system modules are imported but never enabled. For each:
- **If needed**: Add `enable = true` in host config (or fold into a role)
- **If not needed**: Remove from host selector entirely (no import = no eval cost)

Likely candidates for **role absorption**:
- `audio`, `display`, `logind`, `power-management`, `xdg` → `role-desktop`
- `firewall`, `networking` → `role-base` (new)
- `virtualization` → `role-development`
- `flatpak` → `role-desktop` or delete
- `base-programs`, `base-services`, `environment` → `role-base` (new)

### 🟡 P2: Remove mkConfig Boilerplate Where Unused (MEDIUM IMPACT)

For the 9 programs that never branch on `isDarwin` + any system/role modules in the same situation:

**Before**:
```nix
let mkConfig = { isDarwin }: { config, lib, pkgs, ... }: /* same code */;
in {
  flake.modules.nixos.programs-kitty = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-kitty = mkConfig { isDarwin = true; };
}
```

**After**:
```nix
let kittyModule = { config, lib, pkgs, ... }: /* same code */;
in {
  flake.modules.nixos.programs-kitty = kittyModule;
  flake.modules.darwin.programs-kitty = kittyModule;
}
```

Or even better — create a helper `mkDualPlatform` that DRYs this for platform-agnostic modules.

### 🟡 P3: Clean Up ai-tools Orchestration (MEDIUM IMPACT)

- Delete empty `ai-tools/default.nix` or make it a real orchestrator
- Sub-aspects should be self-contained — currently they are, making the default.nix dead

### 🟡 P4: Split Monoliths (MEDIUM IMPACT)

- `wrappers.nix` → split into `wrappers-config.nix`, `wrappers-activation.nix`, `wrappers-scripts.nix`
- `opencode/default.nix` (1101 lines) → split into sub-aspects in `opencode/` folder
- `zsh/default.nix` (1025 lines) → split into `zsh/` sub-aspects

### 🟢 P5: Move Templates Out of flake.nix (LOW IMPACT)

Move template definitions from `flake.nix` to `modules/templates.nix` as a flake-parts module. Keeps flake.nix minimal per dendritic spec.

### 🟢 P6: Feature-Centric Renaming (LOW IMPACT, HIGH EFFORT)

Rename aspects from component-centric to feature-centric:
- `programs-kitty` → `tui-kitty` or just `kitty`
- `system-audio` → `audio`
- `system-display` → `display`
- Drop the `programs-`, `system-`, `services-` prefixes from export names

This is cosmetic but aligns with dendritic philosophy. Low priority — do after architecture is sound.

### 🟢 P7: Consolidate Host Config Layers

Merge `modules/hosts/nixos-desktop.nix` + `hosts/nixos-desktop/config.nix` into one file, or make `hosts/` the sole location and `modules/hosts/` just the host selector with minimal config.

---

## 5. Recommended Migration Order

```
Phase 1 (Quick Wins, 1 day):
├── P1: Enable or remove 12 dead system modules
├── P3: Delete empty ai-tools/default.nix
├── P5: Move templates to modules/
└── Fix: boot/grub-theme.nix enable guard, darwin/defaults.nix enable guard

Phase 2 (Architecture Flip, 2-3 days):
├── P0: Convert roles to import closures (start with development)
├── P0: Shrink host selectors progressively
├── Create role-base for common system aspects
└── Verify via toplevel diff at each step

Phase 3 (Cleanup, 1-2 days):
├── P2: Remove isDarwin boilerplate from 9+ modules
├── P4: Split wrappers.nix, opencode, zsh
├── P7: Consolidate host config layers
└── P6: Feature-centric renaming (optional)
```

---

## Appendix: Module Inventory

**Total**: 88 .nix files across 14 directories

| Category | Count | Pattern |
|---|---|---|
| ai-tools/ | 7 | Own DSL, dendritic exports |
| boot/ | 1 | NixOS-only, no options |
| core/ | 2 | Options definition + wrapper |
| darwin/ | 1 | Darwin-only, no options |
| desktop/hyprland/ | 18 | NixOS-only orchestrator + 17 sub-aspects |
| flake/ | 1 | Module system bootstrapping |
| hardware/ | 6 | NixOS-only, enable options |
| hosts/ | 2 | Host selectors (aspect lists) |
| programs/ | 20 | Per-folder, mkConfig pattern |
| roles/ | 12 | Enable bundles, mkConfig pattern |
| secrets/ | 1 | SOPS config |
| services/ | 3 | mkConfig pattern |
| system/ | 16 | mkConfig pattern, 12 dead |
| root | 4 | Mixed patterns |
