## Wallust Runtime Removal (Task 2)

### Key Files Modified
- `modules/hosts/nixos-desktop/default.nix`: Removed `desktop-hyprland-wallust` import
- `WallustSwww.sh`: Removed `wallust run` call; symlink/copy logic preserved
- `DarkLight.sh`: Removed wallust_config/wallust_rofi variables and their sed operations
- `WallpaperEffects.sh`: Removed two `wallust run` calls in no-effects and effects branches
- `WallpaperAutoChange.sh`: Removed wallust_refresh variable; kept RefreshNoWaybar.sh call inline
- `initial-boot.sh`: Removed `wallust run -s` before swww daemon start

### What Was Preserved
- swww wallpaper setting in all scripts (untouched)
- wallust.nix module file itself (NOT deleted — just no longer imported)
- hyprlock.conf, UserSettings.conf, UserDecorAnimations.conf still `source` the wallust path
  — these are consumers of `~/.config/hypr/wallust/wallust-hyprland.conf` which hypr.nix generates at rebuild time
- rofi.nix, waybar.nix, hypr.nix theme adapters that write to `wallust/` dirs at rebuild time

### Gotcha
- `RefreshNoWaybar.sh` calls `WallustSwww.sh` which chains through `WallpaperAutoChange.sh`. Patching WallustSwww.sh cascades to all callers.
- The flake check error at theme.nix:53 (literal `\n` in string) is pre-existing from parallel work, not from wallust removal.

## Tokyo Night Preset v1

- Added `jvf.theme.presets.tokyonight-night` to `modules/core/theme.nix` (both nixos/darwin exports).
- Exact palette (no #): bg "1a1b26" fg "c0caf5" cursor "c0caf5" color0 "15161e" color1 "f7768e" color2 "9ece6a" color3 "e0af68" color4 "7aa2f7" color5 "bb9af7" color6 "7dcfff" color7 "a9b1d6" color8 "414868" color9 "f7768e" color10 "9ece6a" color11 "e0af68" color12 "7aa2f7" color13 "bb9af7" color14 "7dcfff" color15 "c0caf5".
- Fonts: monospace "JetBrainsMonoNL Nerd Font" sansSerif "DejaVu Sans" size 11.
- GTK: copied from dark-amethyst (Andromeda-dark, Flat-Remix-Blue-Dark, Bibata-Modern-Ice 24).
- rofiSemantic derived: normalBg bg normalFg fg, activeBg color4 activeFg bg, urgentBg color1 urgentFg bg, selectedBg color5 selectedFg bg, border color4.
- `jvf.theme.active` default = lib.mkDefault "tokyonight-night" in theme-options.nix.
- Verification: nix eval returns "tokyonight-night" and "1a1b26".
- Gotchas: Multiline edit tool params need actual newlines (not \\n escapes). LSP minor warnings (unused config arg). nix flake check/format pass after fixes.\n\n## Ghostty Terminal Palette Adapter\n\n- Removed `theme = \"Atom One Dark\"`\n- `themeOverrides` for background/foreground/cursor-color/font-family/font-size from `jvf.theme`\n- `baseSettings = lib.removeAttrs defaultSettings [\"theme\"]`\n- `settings = mkDefault (baseSettings // themeOverrides)`\n- `paletteLines = concatStringsSep \"\\n\" (map (i: \"palette = ${toString i}=#${colors.\\\"color${toString i}\\\"}\") paletteIndices)`\n- `paletteIndices = lib.genList lib.id 16`\n- `configs.\"config\" = toConfigFormat cfg.settings + \"\\n\" + paletteLines`\n- Dendritic: works nixos/darwin\n- Gotcha: attrset keys support `-` (cursor-color)


## tmux theme integration (Task 2)
- tmux-conf.nix signature extended: `{ lib }: { plugins, colors }` — colors comes from `config.jvf.theme.colors`
- Style directives inserted BEFORE `run-shell` plugin lines so explicit styles win over plugin defaults
- Hex colors need `#` prefix in tmux: `fg=#${colors.foreground}` (palette stores without `#`)
- Color mapping: status bg/fg from background/foreground, accent from color4 (blue), dim from color8 (bright black), warning from color3 (yellow)
- Eval path for tmux.conf: `config.jvf.wrappers.users.<user>.programs.tmux.configs."tmux.conf"`
