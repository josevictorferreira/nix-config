# Hyprland Desktop Environment

**Parent:** [../../../AGENTS.md](../../../AGENTS.md)

## OVERVIEW
Hyprland Wayland compositor + Waybar + Rofi + AGS + utilities. 17 modules, 272+ asset files.

## STRUCTURE
```
hyprland/
├── default.nix         # Aggregate/enable wiring
├── hypr.nix            # Compositor: programs.hyprland + assets/hypr materialization
├── theme-switcher.nix  # jvf-theme-switch: deploys dark/light profile artifacts
├── ags.nix             # AGS (Aylur's GTK Shell)
├── waybar.nix          # Status bar
├── rofi.nix            # App launcher
├── cava.nix            # Audio visualizer
├── fastfetch.nix       # System info
├── gtk3.nix            # GTK theme
├── kvantum.nix         # Qt theme
├── qt5ct.nix           # Qt5 config
├── qt6ct.nix           # Qt6 config
├── swappy.nix          # Screenshot editor
├── wallust.nix         # Wallpaper colors
├── wlogout.nix         # Logout menu
├── xfce4.nix           # XFCE app theming
├── swaync.nix          # Notification center
└── assets/             # Co-located configs
    ├── hypr/           # Hyprland Lua config (see below)
    ├── rofi/           # .rasi themes
    ├── waybar/         # config + style.css
    ├── ags/            # AGS modules
    ├── cava/           # shaders
    ├── fastfetch/      # json config
    ├── gtk3/           # settings.ini
    ├── kvantum/        # themes
    ├── wlogout/        # icons
    └── ...
```

## HYPRLAND CONFIG IS LUA (>= 0.55)

hyprlang is deprecated upstream; `assets/hypr/` is a Lua config tree.

```
assets/hypr/
├── hyprland.lua              # entrypoint: debug opts + require() of everything below
├── .luarc.json               # points LuaLS at /run/current-system/sw/share/hypr/stubs
├── configs/{settings,keybinds}.lua
├── UserConfigs/{env,monitors,startup,laptop,window-rules,
│                decor-animations,user-keybinds,user-settings,workspace-rules}.lua
├── wallust/colors.lua        # GENERATED (see colour contract below)
├── hypridle.conf             # hypridle's own format — NOT hyprlang-of-Hyprland
├── hyprlock-2k.conf          # hyprlock still uses hyprlang
└── scripts/ , UserScripts/   # shell helpers
```

Key facts:
- **`.lua` wins over `.conf`, but only at startup** — `hyprctl reload` never
  switches format. Format changes need a full Hyprland restart.
- `require()` resolves **relative to the config root**, independent of cwd, and
  works from files in subdirectories. Each `require`d file is an isolated error
  scope: a broken file does not stop the others from loading.
- Bind callbacks run on the compositor event loop — **never block**. Shell out
  via `hl.dsp.exec_cmd`, never `io.popen`.
- **Verify any change** with `Hyprland --verify-config -c <abs path>/hyprland.lua`.
  It is a real semantic check: it catches unknown config keys, wrong value
  types, unknown window/workspace-rule fields, invalid keysyms and bad
  dispatcher arguments. Bind *option* tables (`{ locked = true }`) are NOT
  validated, so typos there fail silently — check them against the stubs.
- `hl.animation` clamps `speed` to a maximum of 100 (hyprlang accepted more).
- Nested tables replace dotted hyprlang keys: `col.active_border` becomes
  `col = { active_border = ... }`.

## COLOUR CONTRACT (two files, one source)

`hypr.nix` renders `config.jvf.theme.colors` into **both** formats, because the
compositor and hyprlock disagree about config language:

| File | Format | Consumed by |
|---|---|---|
| `wallust/colors.lua` | Lua `return { ... }` | `user-settings.lua`, `decor-animations.lua` |
| `wallust/wallust-hyprland.conf` | hyprlang `$colorN` | `hyprlock-2k.conf` (via `source =`) |

Both are injected by `postInstall` and both ship in
`jvf.theme.profileArtifacts.{dark,light}.hypr`; `theme-switcher.nix` deploys
both, then runs `hyprctl reload`. **Dropping either one breaks something** —
removing the hyprlang file silently unthemes the lock screen.

`hyprland.lua` clears `package.loaded["wallust/colors"]` on each pass so a
reload re-reads the regenerated colours instead of a cached table.

## WHERE TO LOOK
| Task | Location |
|------|----------|
| **Hyprland binds** | `assets/hypr/configs/keybinds.lua`, `UserConfigs/user-keybinds.lua` |
| **Hyprland rules/settings** | `assets/hypr/UserConfigs/*.lua` |
| **Theme colours for hypr** | `hypr.nix` (`mkHyprColorsLua` / `mkHyprColorsConf`) |
| **Waybar modules** | `assets/waybar/config` |
| **Rofi themes** | `assets/rofi/*.rasi` |
| **AGS widgets** | `assets/ags/` |
| **GTK/Qt theming** | `assets/gtk3/`, `assets/kvantum/` |
| **New utility module** | `modules/desktop/hyprland/<name>.nix` |

## CONVENTIONS
- **Co-located assets**: Config files live in `assets/<subsystem>/`
- **Dendritic exports**: Each module exports `flake.modules.nixos.*`
- **Enable pattern**: `jvf.desktop.hyprland.<submodule>.enable` (waybar uses `jvf.home` for config, not wrappers)
- **Asset reference**: Use relative path from module file
- **Config migration**: waybar is migrated to jvf.home for config. Other hyprland sub-modules still use wrappers translation layer.

## ANTI-PATTERNS
- **Inlining configs** - use `writeTextFile` + assets/ files
- **Hardcoded paths** - reference via `${./assets/...}`
- **Enabling by default** - all modules require explicit enable

## CONFIG VS WRAPPER SPLIT
- `jvf.wrappers` handles exactly `packages` / `command` / `env` — **never config
  files**. In `hypr.nix` it only installs hypridle/hyprlock/hyprcursor/pyprland
  (`command = null` ⇒ plain `users.users.*.packages`).
- All config files flow through `jvf.home` (`kind = "dir"; mode = "copy"`) plus
  `postInstall`. Assets are copied **without interpolation**, so no Nix store
  path may appear in a checked-in asset — reference the stable
  `/run/current-system/sw/...` path instead (see `.luarc.json`).
- Wrapper commands are symlinked into `~/.local/bin`, already on the session
  PATH — which is why `hl.exec_cmd("jvf-theme-switch auto")` resolves.

## SCRIPTS COUPLED TO CONFIG SHAPE
These read the config tree rather than the compositor; they must be updated
alongside any renaming of the Lua files:
- `UserScripts/QuickEdit.sh` — menu of config files to open in `$EDITOR`.
- `scripts/SwitchKeyboardLayout.sh` — greps `kb_layout` out of
  `user-settings.lua` (tolerates Lua quoting/trailing comma).
- `scripts/KeyBinds.sh` — reads `hyprctl -j binds` (not files) and renders the
  `description` field of each bind.
- `scripts/{ChangeBlur,ChangeLayout,GameMode,TouchPad}.sh`,
  `UserScripts/RainbowBorders.sh` — mutate live config via `hyprctl eval`.

**`hyprctl` is NOT format-independent.** Under a Lua config:
- `hyprctl dispatch <args>` is evaluated as **Lua**, wrapped as
  `return hl.dispatch(<args>)`. Legacy syntax (`dispatch exec waybar`,
  `dispatch workspace e+1`) is a silent Lua syntax error — the message goes to
  hyprctl's stdout, which callers like Waybar and keybinds discard. Write
  `hyprctl dispatch 'hl.dsp.exec_cmd("waybar")'` instead.
- `hyprctl keyword ...` fails outright: *"keyword can't work with non-legacy
  parsers. Use eval."* Use `hyprctl eval 'hl.config({...})'`; colon paths become
  nested tables (`decoration:blur:size` → `{decoration={blur={size=…}}}`).
- `hyprctl setprop ...` is gone entirely (*"unknown request"*) — use the
  `hl.dsp.window.set_prop` dispatcher.

This applies to every caller, not just the Lua files: Waybar module JSON,
swaync config, hypridle, and any shell script.
