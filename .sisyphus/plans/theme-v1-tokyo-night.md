# Theme v1: Tokyo Night (night) global theming (rebuild-only)

## TL;DR
Single global `config.jvf.theme` preset (Tokyo Night night) drives ghostty + tmux + waybar + rofi + GTK3 (Thunar) via rebuild-generated config files. Remove wallust runtime theming + patch wallpaper scripts so nothing clobbers Nix-owned theme outputs.

**Deliverables (v1)**
- `jvf.theme.presets.tokyonight-night` (+ set as active default)
- Ghostty: `~/.config/ghostty/config` includes explicit 16-color palette (0..15) + bg/fg/cursor + font
- tmux: `~/.config/tmux/tmux.conf` contains explicit style directives from theme (no theme plugin)
- Waybar + Rofi: rebuild-generated `wallust/colors-waybar.css` + `wallust/colors-rofi.rasi` (keeps existing asset imports, but wallust not used)
- GTK3: rebuild-generated `~/.config/gtk-3.0/settings.ini` (font + prefer-dark + theme/icon/cursor)
- Wallust removed from v1 path: no module import, no wallust package, no scripts calling wallust

**Estimated effort**: Medium
**Parallelism**: YES (3 waves + final verification)
**Critical path**: Theme preset/schema → (Ghostty + tmux adapters) → wallust removal/patch scripts → verification

---

## Context

### Original request
Global theming architecture for dendritic NixOS+Darwin flake: define colors+fonts once, easy switching (rebuild-only), modules auto-apply.

### Interview decisions (locked for v1)
- Architecture: Option A (global `jvf.theme` core + per-app adapters)
- v1 apps: ghostty, tmux, waybar, rofi, thunar
- v1 preset: Tokyo Night only, variant **night**
- Token model: palette-first (base16-ish palette canonical; derive semantics where needed)
- GTK/Thunar: **gtk-3.0 settings.ini only** (no dconf)
- Fonts: mono `JetBrainsMonoNL Nerd Font`, sizes mono 11 / UI 11; sans/serif OK to pick defaults
- Wallust: remove module + patch scripts (runtime palette gen not in v1)
- Tests: no new test harness; rely on `nix flake check`/`make check` + QA scenarios

### Key code references (current state)
- Core theme preset currently exists but is `dark-amethyst`: `modules/core/theme.nix`
- Theme schema: `modules/core/_/theme-options.nix`
- Ghostty config writer (attrset→key=value; no repeated keys): `modules/programs/ghostty/default.nix`
- tmux config generator + plugin list: `modules/programs/tmux/_/tmux-conf.nix`, `modules/programs/tmux/options.nix`
- Wallust module + scripts: `modules/desktop/hyprland/wallust.nix` and multiple assets scripts referencing `wallust`

---

## Scope

### IN (v1)
- Add Tokyo Night (night) preset and set default active theme
- Apply theme to ghostty/tmux/waybar/rofi/gtk3
- Remove wallust module and stop scripts from invoking wallust
- Keep existing asset imports by continuing to generate “wallust vars files” at rebuild time (name-only compatibility)

### OUT (v1)
- Multiple theme presets / runtime switching / “live” wallpaper-based palettes
- GTK4 settings.ini generation
- Generating a custom GTK CSS theme from palette
- Refactoring all wallust-named assets (CSS files named “[Wallust] …”) if they’re not on execution path

---

## Verification strategy (mandatory)

**No human verification**. Executor captures evidence under `.sisyphus/evidence/`.

### Primary checks
- `nix flake check` (Linux)
- Targeted eval probes for Darwin configs (Linux can’t fully eval darwinConfigurations): `nix eval .#darwinConfigurations.<host>.config.jvf.theme.active` etc.

### File-level checks (post rebuild)
- Ghostty config: ensure palette lines exist and match theme
- tmux config: ensure `status-style`/`pane-border-style` etc use theme hex
- GTK settings.ini exists and uses UI font size 11
- “wallust vars files” exist but wallust binary/module absent

---

## Execution strategy (parallel waves)

### Wave 1 (foundation + deconflict)
Theme preset/schema alignment + remove wallust module + patch scripts (can run in parallel).

### Wave 2 (app adapters)
Ghostty + tmux + GTK3 updates (parallel).

### Wave 3 (integration + hardening)
Host/role wiring, nix eval probes (NixOS+Darwin), cleanup of stale wallust artifacts, final rebuild QA.

---

## TODOs

- [ ] 1. Add Tokyo Night (night) preset + set v1 defaults

  **What to do**:
  - In `modules/core/theme.nix`, add `config.jvf.theme.presets.tokyonight-night` for both nixos + darwin exports.
  - Replace current `dark-amethyst` usage (either remove, or keep but do not set active by default) and set `jvf.theme.active = "tokyonight-night"` wherever active selection is defined (likely in `theme-options.nix` default).
  - Update theme preset values to match Tokyo Night night palette:
    - `colors.background/foreground/cursor` + `color0..color15`
    - `fonts.monospace = "JetBrainsMonoNL Nerd Font"`
    - set sans/serif defaults (pick sane Nix-available fonts; keep minimal in v1)
    - sizes: mono 11, UI 11 (ensure schema supports per-font size or shared size)
    - keep GTK theme/icon/cursor names as currently in repo unless you explicitly change them.
  - Ensure `backgroundAlpha` is still supported (keep existing value or choose default for Tokyo Night).

  **Must NOT do**:
  - Don’t introduce runtime theme switching (no scripts).
  - Don’t change module activation model (import=active).

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: localized option/preset edits.
  - **Skills**: [`writing-nix-code`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2)
  - **Blocks**: 3,4,5,6
  - **Blocked By**: None

  **References**:
  - `modules/core/theme.nix` - where presets live (currently `dark-amethyst` duplicated for nixos/darwin)
  - `modules/core/_/theme-options.nix` - where `jvf.theme.active` default + resolved config lives

  **Acceptance Criteria**:
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.theme.active` returns `"tokyonight-night"` (or host-specific equivalent)
  - [ ] `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.theme.colors.background` returns a 6-hex string (no #)

  **QA Scenarios**:
  ```
  Scenario: Theme preset resolves (NixOS)
    Tool: Bash
    Steps:
      1. Run: nix eval .#nixosConfigurations.nixos-desktop.config.jvf.theme.colors.color0
      2. Run: nix eval .#nixosConfigurations.nixos-desktop.config.jvf.theme.fonts.monospace
    Expected Result:
      - color0 is non-empty 6-hex
      - monospace == "JetBrainsMonoNL Nerd Font"
    Evidence: .sisyphus/evidence/task-1-theme-eval.txt

  Scenario: Theme preset exists for Darwin module export
    Tool: Bash
    Preconditions: Know darwin host attr name (e.g. macos-macbook)
    Steps:
      1. Run: nix eval .#darwinConfigurations.macos-macbook.config.jvf.theme.presets.tokyonight-night.colors.background
    Expected Result: Non-empty 6-hex
    Evidence: .sisyphus/evidence/task-1-darwin-theme-eval.txt
  ```

- [ ] 2. Remove wallust module from v1 execution path + patch wallpaper scripts

  **What to do**:
  - Stop importing `modules/desktop/hyprland/wallust.nix` from the active host/role path.
  - Remove any wallust package installs that were only for runtime theming.
  - Patch scripts that call `wallust` so wallpaper workflow still works (likely keep `swww` usage), but no palette generation occurs.
  - Ensure no runtime job clobbers Nix-generated:
    - `~/.config/waybar/wallust/colors-waybar.css`
    - `~/.config/rofi/wallust/colors-rofi.rasi`
    - `~/.config/hypr/wallust/wallust-hyprland.conf`
  - Add a cleanup step (activation script or documented manual command) to remove stale `~/.config/wallust/` and caches if they conflict.

  **Must NOT do**:
  - Don’t delete wallust-named CSS themes unless they’re actively referenced; v1 is about removing runtime generation, not mass asset rename.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: crosses module imports + shell scripts + possible activation cleanup.
  - **Skills**: [`writing-nix-code`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 1)
  - **Blocks**: 6 (final verification) and prevents runtime clobbering
  - **Blocked By**: None

  **References**:
  - `modules/desktop/hyprland/wallust.nix` - module to remove from import path
  - Grep results indicate scripts referencing wallust:
    - `modules/desktop/hyprland/assets/hypr/scripts/WallustSwww.sh`
    - `modules/desktop/hyprland/assets/hypr/scripts/DarkLight.sh`
    - `modules/desktop/hyprland/assets/hypr/UserScripts/WallpaperEffects.sh`
    - `modules/desktop/hyprland/assets/hypr/UserScripts/WallpaperAutoChange.sh`
    - `modules/desktop/hyprland/assets/hypr/initial-boot.sh`

  **Acceptance Criteria**:
  - [ ] `nix flake check` still passes
  - [ ] `grep -R "wallust" -n modules/desktop/hyprland/assets/hypr/scripts modules/desktop/hyprland/assets/hypr/UserScripts` shows 0 matches (or only comments)

  **QA Scenarios**:
  ```
  Scenario: No wallust references remain in scripts
    Tool: Bash
    Steps:
      1. Run: grep -R "wallust" -n modules/desktop/hyprland/assets/hypr/scripts modules/desktop/hyprland/assets/hypr/UserScripts || true
    Expected Result: empty output
    Evidence: .sisyphus/evidence/task-2-no-wallust-grep.txt
  ```

- [ ] 3. Ghostty: generate explicit Tokyo Night palette in config output

  **What to do**:
  - In `modules/programs/ghostty/default.nix`, consume `config.jvf.theme.*`.
  - Keep `cfg.settings` generation for normal keys, but append palette lines as raw string because the current `toConfigFormat` cannot represent repeated keys.
  - Replace `defaultSettings.theme = "Atom One Dark"` with explicit palette generation (or set `theme = ""` if ghostty treats explicit colors as override).
  - Ensure font-family is `config.jvf.theme.fonts.monospace` and font-size is 11 (v1).
  - Ghostty palette lines must map:
    - `palette = 0=#${color0}` … `palette = 15=#${color15}`
    - plus `background = #${background}`, `foreground = #${foreground}`, `cursor-color = #${cursor}` (exact key names verify vs ghostty docs or current usage patterns).

  **Must NOT do**:
  - Don’t introduce runtime theme loader.
  - Don’t change wrappers contract; only change ghostty module output.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`writing-nix-code`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4,5)
  - **Blocks**: 6
  - **Blocked By**: 1

  **References**:
  - `modules/programs/ghostty/default.nix` - config generation (`configs."config" = toConfigFormat cfg.settings`)
  - Theme schema: `config.jvf.theme.colors.*` in `modules/core/_/theme-options.nix`

  **Acceptance Criteria**:
  - [ ] After rebuild, `~/.config/ghostty/config` contains 16 `palette =` lines
  - [ ] File contains `font-family = JetBrainsMonoNL Nerd Font` and `font-size = 11`

  **QA Scenarios**:
  ```
  Scenario: Ghostty config includes explicit palette
    Tool: Bash
    Steps:
      1. Run: grep -n "^palette = " ~/.config/ghostty/config | wc -l
      2. Run: grep -n "^palette = 0=#" ~/.config/ghostty/config
      3. Run: grep -n "^font-family = JetBrainsMonoNL Nerd Font$" ~/.config/ghostty/config
    Expected Result:
      - count == 16
      - palette 0 present
      - font family line present
    Evidence: .sisyphus/evidence/task-3-ghostty-palette.txt

  Scenario: Ghostty config has bg/fg/cursor set
    Tool: Bash
    Steps:
      1. Run: grep -nE "^(background|foreground|cursor-color) = #" ~/.config/ghostty/config
    Expected Result: 3 lines match
    Evidence: .sisyphus/evidence/task-3-ghostty-bgc.txt
  ```

- [ ] 4. tmux: generate style directives from theme; drop onedark-theme plugin

  **What to do**:
  - Remove `pkgs.tmuxPlugins.onedark-theme` from tmux defaults in `modules/programs/tmux/options.nix`.
  - Extend `modules/programs/tmux/_/tmux-conf.nix` to accept theme colors (palette-first) and emit style directives:
    - `status-style`, `status-left-style`, `status-right-style`
    - `window-status-style`, `window-status-current-style`
    - `pane-border-style`, `pane-active-border-style`
    - `message-style`, `mode-style`
  - Ensure hex formatting includes leading `#`.

  **Must NOT do**:
  - Don’t break existing keybinds / tmuxp picker binding.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: [`writing-nix-code`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 3,5)
  - **Blocks**: 6
  - **Blocked By**: 1

  **References**:
  - `modules/programs/tmux/_/tmux-conf.nix` - where tmux.conf string is built
  - `modules/programs/tmux/default.nix` - calls mkTmuxConf; needs to pass theme colors
  - `modules/programs/tmux/options.nix` - default plugins include onedark-theme

  **Acceptance Criteria**:
  - [ ] After rebuild, `~/.config/tmux/tmux.conf` contains `status-style` with `#RRGGBB`
  - [ ] `onedark-theme` no longer present in evaluated plugin list

  **QA Scenarios**:
  ```
  Scenario: tmux.conf contains explicit styles
    Tool: Bash
    Steps:
      1. Run: grep -n "^set -g status-style" ~/.config/tmux/tmux.conf
      2. Run: grep -n "pane-border-style" ~/.config/tmux/tmux.conf
    Expected Result: lines exist and include '#'
    Evidence: .sisyphus/evidence/task-4-tmux-styles.txt

  Scenario: onedark theme plugin removed
    Tool: Bash
    Steps:
      1. Run: nix eval .#nixosConfigurations.nixos-desktop.config.jvf.programs.tmux.plugins | grep -i onedark || true
    Expected Result: empty output
    Evidence: .sisyphus/evidence/task-4-no-onedark-eval.txt
  ```

- [ ] 5. Waybar + Rofi: verify rebuild-generated vars files are theme-owned (no wallust runtime)

  **What to do**:
  - Confirm `modules/desktop/hyprland/waybar.nix` generates `~/.config/waybar/wallust/colors-waybar.css` from `config.jvf.theme.colors`.
  - Confirm `modules/desktop/hyprland/rofi.nix` generates `~/.config/rofi/wallust/colors-rofi.rasi` from `config.jvf.theme`.
  - If `rofiSemantic` is required by the adapter, set `presets.tokyonight-night.rofiSemantic` fields in Task 1 (derive from palette).
  - Ensure no wallpaper script triggers wallust generation that would overwrite these files (covered in Task 2).

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`writing-nix-code`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 3,4,6)
  - **Blocks**: 7
  - **Blocked By**: 1,2

  **References**:
  - `modules/desktop/hyprland/waybar.nix` - build-time generator
  - `modules/desktop/hyprland/rofi.nix` - build-time generator
  - Any waybar/rofi asset that imports the generated vars paths

  **Acceptance Criteria**:
  - [ ] After rebuild, both files exist:
    - `~/.config/waybar/wallust/colors-waybar.css`
    - `~/.config/rofi/wallust/colors-rofi.rasi`

  **QA Scenarios**:
  ```
  Scenario: Vars files exist post-rebuild
    Tool: Bash
    Steps:
      1. Run: test -f ~/.config/waybar/wallust/colors-waybar.css && echo OK
      2. Run: test -f ~/.config/rofi/wallust/colors-rofi.rasi && echo OK
    Expected Result: prints OK twice
    Evidence: .sisyphus/evidence/task-5-vars-exist.txt
  ```

- [ ] 6. GTK3 (Thunar): ensure gtk-3.0 settings.ini uses theme fonts + theme/icon/cursor

  **What to do**:
  - Confirm `modules/desktop/hyprland/gtk3.nix` generates `~/.config/gtk-3.0/settings.ini` via wrappers.
  - Ensure values come from `config.jvf.theme.gtk.*` + UI font with size 11.
  - Ensure `gtk-application-prefer-dark-theme=1` is present.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`writing-nix-code`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 3,4)
  - **Blocks**: 6
  - **Blocked By**: 1

  **References**:
  - `modules/desktop/hyprland/gtk3.nix` - existing adapter

  **Acceptance Criteria**:
  - [ ] After rebuild, `~/.config/gtk-3.0/settings.ini` contains `gtk-font-name` with size 11
  - [ ] File contains theme/icon/cursor keys

  **QA Scenarios**:
  ```
  Scenario: gtk settings.ini present + correct
    Tool: Bash
    Steps:
      1. Run: grep -n "^gtk-font-name=" ~/.config/gtk-3.0/settings.ini
      2. Run: grep -n "gtk-application-prefer-dark-theme=1" ~/.config/gtk-3.0/settings.ini
    Expected Result: both lines exist
    Evidence: .sisyphus/evidence/task-6-gtk-settings.txt
  ```

- [ ] 7. Integration + verification

  **What to do**:
  - Run `nix flake check`.
  - Run minimal eval probes for Darwin (replace host attr):
    - `nix eval .#darwinConfigurations.<host>.config.jvf.theme.presets.tokyonight-night.colors.background`
  - Rebuild target host (as applicable) and capture evidence of generated files.
  - Grep for wallust remaining in active Nix modules (allow in unused assets if not executed, but ensure no imports/scripts).

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: [`git-master`]

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3
  - **Blocks**: Final verification wave
  - **Blocked By**: 1-5

  **Acceptance Criteria**:
  - [ ] `nix flake check` PASS
  - [ ] Evidence files from tasks exist under `.sisyphus/evidence/`

  **QA Scenarios**:
  ```
  Scenario: Full flake check
    Tool: Bash
    Steps:
      1. Run: nix flake check
    Expected Result: exit 0
    Evidence: .sisyphus/evidence/task-7-flake-check.txt
  ```

---

## Final Verification Wave

- F1 (oracle): plan compliance audit + scope creep check
- F2 (unspecified-high): nix/lint/style sanity (if present) + grep for wallust refs in active path
- F3 (unspecified-high): run all QA scenarios + capture evidence
- F4 (deep): dependency + contamination scan (tasks only touch intended files)

---

## Commit strategy
Prefer small commits per wave:
- `feat(theme): add tokyo night preset + schema updates`
- `chore(wallust): remove module + patch wallpaper scripts`
- `feat(ghostty): generate explicit palette from jvf.theme`
- `feat(tmux): generate styles from jvf.theme, drop onedark plugin`
- `feat(gtk): generate gtk-3.0 settings.ini from jvf.theme`
- `chore: verification + cleanup`

---

## Success criteria
- Switching `config.jvf.theme.active` + rebuild deterministically changes ghostty/tmux/waybar/rofi/gtk3 outputs
- No wallust runtime theming remains in the v1 execution path (imports/packages/scripts)
- `nix flake check` passes; targeted Darwin eval probes pass
