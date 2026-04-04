# jvf.wrappers → jvf.home Config Migration Plan

Migrate 26 modules from legacy `jvf.wrappers.*.configs` to direct `jvf.home.users.*.items` usage.

## Migration Pattern

Every module follows the same transformation:

```
# BEFORE (legacy wrappers)
jvf.wrappers.users.${u}.programs.<name> = {
  packages = [ ... ];          # KEEP in wrappers
  configs = { ... };           # MOVE to jvf.home
  postInstall = ''...'';       # MOVE to jvf.home
  preserveFiles = [ ... ];     # MOVE to jvf.home as preserve
  configPath = ".<dir>";       # MOVE to jvf.home as target path
};

# AFTER (migrated)
jvf.wrappers.users.${u}.programs.<name> = {
  packages = [ ... ];          # stays
};
jvf.home.users.${u}.items."<path>" = {
  kind = "file" | "dir";
  mode = "copy";              # default
  source = ...;               # for dirs/assets
  text = ...;                 # for inline content
  preserve = [ ... ];         # from preserveFiles
  postInstall = ''...'';      # from postInstall
};
```

### Path Mapping Rules
- No `configPath` → target is `".config/<program>/..."`
- `configPath = ".gemini"` → target is `".gemini/..."`
- Single file configs → `kind = "file"` + target `".config/<prog>/<file>"`
- Asset directory → `kind = "dir"` + target `".config/<prog>"` with `source = ./assets/<prog>/.;`
- Structured attrs (Nix → file) → use appropriate serializer: `json`, `yaml`, `toml`, `ini` fields

### Reference Implementations
- **File + text**: kitty (`modules/programs/kitty/default.nix:151`)
- **Dir + source + postInstall**: waybar (`modules/desktop/hyprland/waybar.nix:100`)

---

## Already Migrated (3/29)

| Module | Config Location | Wrappers Remaining |
|--------|----------------|-------------------|
| waybar | `items.".config/waybar"` (dir) | packages only |
| kitty | `items.".config/kitty/kitty.conf"` (file) | packages only |
| claudecode | `items.".claude"` + `".claude-code-router"` (dirs) | packages + env |

---

## Phase 1: Simple Configs-Only (14 modules)

All have `configs = { ... }` with no `postInstall`, `preserveFiles`, or `configPath`.
Keep `packages` in wrappers, move configs to jvf.home.

### Batch 1A: Desktop Hyprland — Static Files (6)

| # | Module | File | Config Content | Target Path | Kind |
|---|--------|------|---------------|-------------|------|
| 1.1 | fastfetch | `hyprland/fastfetch.nix` | 3 jsonc + 1 png | `.config/fastfetch` | dir (mixed: text files + binary) |
| 1.2 | cava | `hyprland/cava.nix` | cava.conf (attrset) + shaders dir | `.config/cava` | dir (attrset + asset dir) |
| 1.3 | xfce4 | `hyprland/xfce4.nix` | xfce4/terminalrc | `.config/xfce4/terminal` | file |
| 1.4 | wlogout | `hyprland/wlogout.nix` | style + icons | `.config/wlogout` | dir |
| 1.5 | wallust | `hyprland/wallust.nix` | wallust config + templates | `.config/wallust` | dir |
| 1.6 | thunar | `hyprland/thunar.nix` | thunar settings | `.config/Thunar` | file(s) |

**Notes:**
- fastfetch: 3 inline text configs + 1 binary png. Use `dir` with `source` containing all files, OR separate file items. Binary png requires `source` not `text`.
- cava: structured attrset (`cavaConfig`) + asset dir (`./assets/cava/shaders`). May need two items or a merged derivation.

### Batch 1B: Desktop Hyprland — Theme/Qt (4) ✅ COMPLETE (commit 579dc56)

| # | Module | File | Config Content | Target Path | Kind |
|---|--------|------|---------------|-------------|------|
| 1.7 | swappy | `hyprland/swappy.nix` | swappy config | `.config/swappy/config` | file |
| 1.8 | qt6ct | `hyprland/qt6ct.nix` | qt6ct.conf | `.config/qt6ct/qt6ct.conf` | file |
| 1.9 | qt5ct | `hyprland/qt5ct.nix` | qt5ct.conf | `.config/qt5ct/qt5ct.conf` | file |
| 1.10 | kvantum | `hyprland/kvantum.nix` | kvantum theme | `.config/Kvantum` | dir |

### Batch 1C: Programs — Simple (5)

| # | Module | File | Config Content | Target Path | Kind |
|---|--------|------|---------------|-------------|------|
| 1.11 | alacritty | `programs/alacritty/default.nix` | toml config | `.config/alacritty/alacritty.toml` | file |
| 1.12 | btop | `programs/btop/default.nix` | btop.conf | `.config/btop/btop.conf` | file |
| 1.13 | git | `programs/git/default.nix` | gitconfig | `.gitconfig` | file |
| 1.14 | k9s | `programs/k9s/default.nix` | skin + shortcuts + aliases + plugins | `.config/k9s` | dir (multi-file) |
| 1.15 | ghostty | `programs/ghostty/default.nix` | ghostty config | `.config/ghostty/config` | file |

**Notes:**
- ghostty: marked "complex" in audit but config structure is simple (single file, may have theme adapter)
- k9s: multiple configs (skin, shortcuts, aliases, views, plugins) — either separate file items or merged dir

---

## Phase 2: Configs + postInstall (5 modules)

These have `postInstall` scripts that run after config deployment (typically theme color injection).

| # | Module | File | Config Content | postInstall Purpose | Target Path |
|---|--------|------|---------------|---------------------|-------------|
| 2.1 | hypr | `hyprland/hypr.nix` | hypr dir + pypr dir | Inject wallust colors + Battery.sh + hyprctl reload | `.config/hypr` (dir with subdirs) |
| 2.2 | ags | `hyprland/ags.nix` | ags dir | Inject theme-colors.css into user/ | `.config/ags` (dir) |
| 2.3 | rofi | `hyprland/rofi.nix` | rofi themes + configs | Inject wallust colors | `.config/rofi` (dir) |
| 2.4 | gtk3 | `hyprland/gtk3.nix` | settings.ini + folder icons | Copy folder icons to icons/ | `.config/gtk-3.0` (dir) |
| 2.5 | swaync | `hyprland/swaync.nix` | swaync configs | Make scripts executable | `.config/swaync` (dir) | ✅

**Migration Pattern:**
```nix
# Each module: configs → dir item with source + postInstall
jvf.home.users.${u}.items.".config/<prog>" = {
  kind = "dir";
  mode = "copy";
  source = ./assets/<prog>;
  postInstall = ''<adapted from wrappers postInstall>'';
};
```

**Key difference from Phase 1:** postInstall scripts use `$TARGET_PATH`, `$HOME_DIR` etc. — same env vars as jvf.home postInstall, so mostly direct copy.

---

## Phase 3: configPath + preserveFiles (4 modules)

These use `configPath` (non-standard target dir like `~/.gemini/`) and `preserveFiles` (files to keep across rebuilds).

| # | Module | File | configPath | preserveFiles | Config Content |
|---|--------|------|-----------|--------------|----------------|
| 3.1 | gemini | `programs/gemini/default.nix` | `.gemini` | 12 items (auth, history, etc.) | mkMerge: toml configs + settings.json + GEMINI.md |
| 3.2 | droid | `programs/droid/default.nix` | `.factory` | Unknown | configs + tools |
| 3.3 | hermes-agent | `programs/hermes-agent/default.nix` | `.hermes` | Unknown | configs |
| 3.4 | opencode | `programs/opencode/default.nix` | (default `.config/opencode`) | Unknown | configs + settings |

**Migration Pattern:**
```nix
# configPath → custom target, preserveFiles → preserve list
jvf.home.users.${u}.items.".gemini" = {
  kind = "dir";
  mode = "copy";
  source = configPkg;  # derivation merging all configs
  preserve = [ "antigravity" "history" "tmp" ... ];
};
```

**Notes:**
- gemini is the most complex: `mkMerge` of ai-tools generated TOML + settings.json + GEMINI.md. Need to build a derivation that merges all these, or use multiple file items.
- These may need to stay as dir items with `source = <derivation>` since they have mixed content types.

---

## Phase 4: Complex / Special Cases (2 modules)

| # | Module | File | Complexity |
|---|--------|------|-----------|
| 4.1 | cursor | `programs/cursor/default.nix` | configPath(`.cursor`) — single target dir |
| 4.2 | tmux | `programs/tmux/default.nix` | Two wrappers blocks (tmux + tmuxp) — dual config targets |

**Notes:**
- cursor: `configPath = ".cursor"` with configs. Single target, straightforward once pattern is established.
- tmux: Has both `programs.tmux` and `programs.tmuxp` wrappers blocks. Both need migration. Two separate jvf.home items.

---

## Phase 5: Cleanup

| # | Task | Description |
|---|------|-------------|
| 5.1 | Remove dead wrappers options | After all consumers migrated, remove `configs`, `postInstall`, `preserveFiles`, `configPath`, `useDerivationConfig` option definitions from `wrappers.nix` |
| 5.2 | Remove translation layer | Delete the auto-translation code in `wrappers.nix` that converts legacy `configs` → `jvf.home` items |
| 5.3 | Update AGENTS.md | Update conventions to note all modules use jvf.home directly |
| 5.4 | Final `nix flake check` | Verify full eval after cleanup |

---

## Verification Checklist (per module)

After each module migration:
1. `nix flake check` passes
2. No `configs`, `postInstall`, `preserveFiles`, `configPath` remain in wrappers block
3. `packages` and `env` remain in wrappers (unchanged)
4. jvf.home item has correct `kind`, `mode`, target path
5. If postInstall existed: script uses same env vars (`$TARGET_PATH`, `$HOME_DIR`)

---

## Execution Order

```
Phase 1 (14 modules) → verify batch
Phase 2 (5 modules)  → verify batch
Phase 3 (4 modules)  → verify batch
Phase 4 (2 modules)  → verify batch
Phase 5 (cleanup)    → final verify
```

Modules within each phase can be migrated in parallel (independent files).
Run `nix flake check` after each phase completes.

## Estimated Effort

| Phase | Modules | Difficulty | Est. Time |
|-------|---------|-----------|-----------|
| 1 | 14 | Low (mechanical) | 2-3h |
| 2 | 5 | Medium (postInstall scripts) | 1-2h |
| 3 | 4 | Medium-High (preserve + custom paths) | 1-2h |
| 4 | 2 | Medium (special cases) | 30min-1h |
| 5 | cleanup | Low | 30min |
| **Total** | **26** | | **5-8h** |
