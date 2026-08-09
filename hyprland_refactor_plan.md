# Hyprland Lua Config Refactor Plan

Status: proposal (2026-08-09)
Scope: migrate `modules/desktop/hyprland/` from hyprlang `.conf` files to the new Lua configuration introduced in Hyprland 0.55.

---

## 1. Why now

- Since **Hyprland 0.55, hyprlang is deprecated in favor of Lua**. The config lives at
  `~/.config/hypr/hyprland.lua`. If both files exist, **`hyprland.lua` wins** — but the
  check happens **only at startup**, not on `hyprctl reload`.
- Upstream commits to keeping hyprlang working for **only 1–2 releases after 0.55**, with
  no new features. We are pinned to and running **0.56.1** (`pkgs.hyprland` from
  nixos-unstable), so we are already inside the removal window. Migrating now is
  maintenance, not adventure; waiting risks a broken desktop on a routine `flake-update`.
- Upsides beyond survival: `require()`-scoped multi-file configs (an error in one file no
  longer kills the rest), real functions in binds, event hooks (`hl.on`), timers, and a
  `hyprctl` REPL for live debugging.

Sources: [Start Here](https://wiki.hypr.land/Configuring/Start/),
[Lua-ification announcement](https://hypr.land/news/26_lua/),
[Binds](https://wiki.hypr.land/Configuring/Basics/Binds/),
[Variables](https://wiki.hypr.land/Configuring/Basics/Variables/),
[Monitors](https://wiki.hypr.land/Configuring/Basics/Monitors/),
[Window Rules](https://wiki.hypr.land/Configuring/Basics/Window-Rules/),
[Autostart](https://wiki.hypr.land/Configuring/Basics/Autostart/),
[Hyprland on NixOS](https://wiki.hypr.land/Nix/Hyprland-on-NixOS/),
[Hyprland on Home Manager](https://wiki.hypr.land/Nix/Hyprland-on-Home-Manager/).

## 2. New configuration model — what the research found

### 2.1 Lua API (Hyprland ≥ 0.55)

| Concern | hyprlang (old) | Lua (new) |
|---|---|---|
| Options | `general { gaps_in = 6 }` | `hl.config({ general = { gaps_in = 6 } })` — multiple `hl.config()` calls merge |
| Binds | `bind = $mainMod, Q, killactive,` | `hl.bind("SUPER + Q", hl.dsp.window.close())` |
| Bind flags | `binde`/`bindl`/`bindn` suffix letters | third arg table: `{ repeating = true, locked = true, non_consuming = true, description = "..." }` |
| Exec bind | `bind = ..., exec, cmd` | `hl.bind(keys, hl.dsp.exec_cmd("cmd"))` |
| Dispatchers | comma strings | typed tables: `hl.dsp.window.*`, `hl.dsp.workspace.*`, `hl.dsp.group.*`, `hl.dsp.focus{...}`, `hl.dispatch(...)` from functions |
| Submaps | `submap = resize` blocks | `hl.define_submap("resize", function() ... end)` |
| Monitors | `monitor = DP-1, 3440x1440@165, auto, 1` | `hl.monitor({ output = "DP-1", mode = "3440x1440@165", position = "auto", scale = 1 })` |
| Window rules | `windowrule = match:class ^(x)$, float on` | `hl.window_rule({ match = { class = "^(x)$" }, float = true, ... })` |
| Workspace rules | `workspace = 1, monitor:DP-1` | `hl.workspace_rule(...)` (same table style; confirm exact fields on the Workspace Rules wiki page during implementation) |
| Autostart | `exec-once = cmd` | `hl.on("hyprland.start", function() hl.exec_cmd("cmd") end)` — async, no `& disown` needed |
| Env vars | `env = NAME,value` | set on the `hyprland.start`/config path (confirm exact call on the Environment Variables wiki page during implementation) |
| Variables | `$mainMod = SUPER` | plain Lua: `local mainMod = "SUPER"`, string concat in binds |
| Includes | `source = path.conf` | `require("configs/keybinds")` — each file is an isolated error scope; wildcards (`require("./stuff/*")`) supported |
| Colors | `$color12 = rgb(...)` sourced file | a Lua module returning a table: `local colors = require("wallust/colors")` |

Other facts that shape the plan:

- **Error containment**: syntax errors abort only the current file; `require()`d files fail
  independently. Emergency binds (SUPER+Q/R/M) exist if the config dies before binds load.
- **Keybind callbacks must not block** (they run on the compositor event loop) — external
  commands must go through `hl.dsp.exec_cmd`. All our current binds already shell out, so
  a mechanical translation is safe.
- **LSP stubs** ship with Hyprland (`share/hypr/stubs` in the package) — a `.luarc.json`
  in the assets dir gives autocompletion while editing.
- Gestures replace `workspace_swipe*` options with `hl.gesture({ fingers = 3, ... })`.

### 2.2 Nix integration status

- The **NixOS module is unchanged**: `programs.hyprland.enable` still provides portals,
  session file, drivers. Nothing to do there.
- **Home Manager 26.05** added `wayland.windowManager.hyprland.configType = "lua"`, a
  Nix-attrs→Lua generator (`_args`, `_var`, `mkLuaInline`) and `extraLuaFiles`.
  **Not applicable to us**: this repo deliberately has no home-manager
  (`AGENTS.md` bans `xdg.configFile`/HM options repo-wide; config files go through
  `jvf.home`). Also, the settings→Lua generator is young (home-manager issue #9468:
  invalid Lua emitted for `$`-style variables, closed "not planned") — writing native
  `.lua` files is the robust path even for HM users.

**Conclusion**: keep our architecture exactly as-is (raw files under
`assets/hypr/`, materialized by `jvf.home` with `kind = "dir"; mode = "copy"`), and
translate the *content* from hyprlang to Lua. The new model actually fits our
multi-file layout better than hyprlang did, because `require()` gives per-file error
isolation that `source =` never had.

## 3. Current state (survey summary)

- `modules/desktop/hyprland/hypr.nix` — `programs.hyprland.enable = true`,
  `package = pkgs.hyprland` (0.56.1); materializes `assets/hypr/` → `~/.config/hypr`
  via `jvf.home`; `postInstall` injects the generated color file and runs
  `hyprctl reload` when a session is live.
- Config graph: `hyprland.conf` → `source =` → `configs/{Settings,Keybinds}.conf` +
  `UserConfigs/{ENVariables,Monitors,Startup_Apps,Laptops,LaptopDisplay,WindowRules,
  UserDecorAnimations,UserKeybinds,UserSettings,WorkspaceRules}.conf`.
- Theme system: `hypr.nix` renders `$colorN` hyprlang variables from
  `config.jvf.theme.colors` into `wallust/wallust-hyprland.conf`; dark/light variants are
  published as `jvf.theme.profileArtifacts.{dark,light}.hypr`; `theme-switcher.nix`
  deploys the active profile's file into `~/.config/hypr/wallust/` and runs
  `hyprctl reload`.
- `hypridle.conf`, `hyprlock*.conf`, `pypr/config.toml`, and the 47 shell scripts are
  configs of *other* programs and are **not affected** by the compositor's Lua switch.
- The `hyprland` flake input in `flake.nix:10-11` is declared but **unused** (zero
  references; ~10 extra lock nodes).

## 4. Design decisions

1. **Keep `jvf.home` copy mechanism unchanged.** Only the asset content changes. No new
   Nix options, no home-manager.
2. **Mirror the current file split 1:1** so review is a file-by-file diff:
   each `X.conf` becomes `X.lua`, wired with `require()` from `hyprland.lua`.
3. **Colors become a Lua module.** `hypr.nix` renders `wallust/colors.lua` that
   `return`s a table (`{ background = "rgb(...)", color0 = ..., color15 = ..., }`).
   The theme artifact contract (`jvf.theme.profileArtifacts.*.hypr`) and the
   theme-switcher deploy path change filename only. `hyprctl reload` re-executes the
   Lua config, so runtime theme switching keeps working.
4. **Do not migrate** hypridle/hyprlock/pyprland configs — they don't use hyprlang-of-
   Hyprland; they keep their own formats.
5. **Cut over atomically per activation, restart to adopt.** Because the
   `.lua`-over-`.conf` precedence check is startup-only, the first rebuild that ships
   `hyprland.lua` has no effect on the running session until Hyprland restarts. We keep
   the `.conf` tree in place during Phases 1–3 (inert while `.lua` exists after restart,
   live again if `.lua` is deleted = instant rollback), and delete it in Phase 5.
6. **Drop the unused `hyprland` flake input.** nixpkgs-unstable at 0.56.1 already
   satisfies the Lua requirement; the input only bloats `flake.lock`. (If we ever need
   -git, re-add it *and* set both `package` and `portalPackage` per the wiki.)
7. **Respect the config-vs-wrapper split** (`modules/wrappers.nix` contract, enforced by
   AGENTS.md). `jvf.wrappers` handles exactly `packages`/`command`/`env` — never config
   files. This plan touches wrappers **zero times**: the
   `jvf.wrappers...programs.hypr.packages` block (hypridle, hyprlock, hyprcursor,
   pyprland; `command = null` ⇒ plain `users.users.*.packages` install) stays as-is, and
   all config flows through `jvf.home` asset copies + `postInstall`. Note
   `hl.exec_cmd("jvf-theme-switch auto")` keeps resolving because wrapper commands are
   symlinked into `~/.local/bin` (already on the session PATH — the current
   `Startup_Apps.conf` calls it the same way) and `exec_cmd` runs via `sh -c` exactly
   like `exec-once` did.

## 5. Target layout

```
modules/desktop/hyprland/assets/hypr/
├── hyprland.lua              # entrypoint: requires everything below
├── .luarc.json               # LSP stubs pointer (editor DX only)
├── configs/
│   ├── settings.lua          # was configs/Settings.conf (initial-boot exec-once)
│   └── keybinds.lua          # was configs/Keybinds.conf
├── UserConfigs/
│   ├── env.lua               # was ENVariables.conf
│   ├── monitors.lua          # was Monitors.conf
│   ├── startup.lua           # was Startup_Apps.conf
│   ├── laptop.lua            # was Laptops.conf + LaptopDisplay.conf (merged; both are lid/brightness concerns)
│   ├── window-rules.lua      # was WindowRules.conf
│   ├── decor-animations.lua  # was UserDecorAnimations.conf
│   ├── user-keybinds.lua     # was UserKeybinds.conf
│   ├── user-settings.lua     # was UserSettings.conf
│   └── workspace-rules.lua   # was WorkspaceRules.conf
├── wallust/colors.lua        # checked-in placeholder; overwritten by postInstall (unchanged pattern)
├── hypridle.conf             # unchanged (hypridle's own format)
├── hyprlock-2k.conf          # unchanged (hyprlock's own format)
├── initial-boot.sh           # unchanged
├── scripts/ , UserScripts/   # unchanged
```

`hyprland.lua` sketch:

```lua
hl.config({ debug = { damage_tracking = 2, disable_logs = false, disable_time = false } })

require("configs/settings")
require("configs/keybinds")
require("UserConfigs/env")
require("UserConfigs/monitors")
require("UserConfigs/startup")
require("UserConfigs/laptop")
require("UserConfigs/window-rules")
require("UserConfigs/decor-animations")
require("UserConfigs/user-keybinds")
require("UserConfigs/user-settings")
require("UserConfigs/workspace-rules")
```

Representative translations (full mapping in §2.1):

```lua
-- wallust/colors.lua (generated by hypr.nix)
return {
  background = "rgb(1a1b26)",
  color8  = "rgb(414868)",
  color12 = "rgb(7aa2f7)",
  -- ... color0..color15, foreground, placeholderFg
}

-- UserConfigs/user-settings.lua (excerpt)
local colors = require("wallust/colors")
hl.config({
  general = {
    border_size = 2,
    gaps_in = 6,
    gaps_out = 8,
    layout = "dwindle",
    ["col.active_border"] = colors.color12,   -- dotted keys need bracket syntax
    ["col.inactive_border"] = colors.color8,
  },
  input = { kb_layout = "us", repeat_rate = 50, follow_mouse = 2, numlock_by_default = true },
  misc  = { enable_swallow = true, swallow_regex = "^(kitty)$" },
})

-- configs/keybinds.lua (excerpt)
local mainMod = "SUPER"
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({}))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"))
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Wlogout.sh"))
for i = 1, 10 do
  local key = tostring(i % 10)
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
  hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end

-- UserConfigs/window-rules.lua (excerpt)
hl.window_rule({
  match = { class = "^(yazi-fm)$" },
  float = true, center = true, size = { 900, 600 },
  workspace = "special:yazi silent",
})

-- UserConfigs/startup.lua (excerpt)
hl.on("hyprland.start", function()
  hl.exec_cmd("jvf-theme-switch auto")
  hl.exec_cmd("waybar")
  hl.exec_cmd("swaync")
  hl.exec_cmd("pypr")
  -- ... (exec_cmd is async; the trailing '&' from the .conf era is dropped)
end)
```

## 6. Implementation phases

Each phase is a separate commit with its own verification; the desktop stays on the
`.conf` tree until Phase 5.

### Phase 0 — Baseline snapshot
1. Record current behavior: `hyprctl binds -j`, `hyprctl monitors -j`,
   `hyprctl workspacerules -j`, `hyprctl clients -j` → save under
   `.omc/` or scratch for later diffing.
   → verify: files captured, non-empty.

### Phase 1 — Scaffold + settings/decor/colors
1. Add `assets/hypr/hyprland.lua` requiring only what Phase 1 delivers; add a
   verbatim `.luarc.json` pointing at `/run/current-system/sw/share/hypr/stubs`
   (verified to exist — `programs.hyprland.enable` links the package into the system
   profile). Assets are copied without interpolation, so no store path may appear in
   checked-in files; this stable path avoids that entirely.
2. In `hypr.nix`, change `mkHyprColorsConf` to emit `colors.lua` (Lua table) instead of
   hyprlang variables; keep filename/artifact wiring consistent:
   `postInstall` copies to `$TARGET_PATH/wallust/colors.lua`; dark/light artifacts now
   contain `colors.lua`.
3. Translate `UserSettings.conf` → `user-settings.lua`,
   `UserDecorAnimations.conf` → `decor-animations.lua` (check the Animations wiki page
   for the Lua bezier/animation API — including the `borderangle ... loop` used by
   RainbowBorders — before translating this file).
4. Update `theme-switcher.nix` deploy path: `hypr/wallust-hyprland.conf` →
   `hypr/colors.lua` (source and target names).
   → verify: `nix eval .#nixosConfigurations.nixos-desktop.config.system.build.toplevel`
   and `nix flake check` pass (theme-switcher VM test exercises the deploy path);
   `lua -e "local c = dofile('modules/desktop/hyprland/assets/hypr/wallust/colors.lua'); assert(c)"`-style syntax check for every new `.lua` file
   (or `luajit -bl` / `luac -p` as a pure parse check).

### Phase 2 — Keybinds
1. Translate `configs/Keybinds.conf` → `configs/keybinds.lua` and
   `UserConfigs/UserKeybinds.conf` → `user-keybinds.lua`.
   Flag mapping: `binde` → `{ repeating = true }`, `bindl` → `{ locked = true }`,
   `bindn` (ALT_L,SHIFT_L layout switch) → `{ non_consuming = true }`,
   mouse binds → `{ mouse = true }` with `hl.dsp.window.drag()/resize()`.
2. Add `{ description = "..." }` to the binds that KeyHints.sh surfaces (free feature of
   the new format; `hyprctl binds` exposes them).
   → verify: `luac -p` parse checks; grep-count parity — number of `bind*` lines in the
   old files equals number of `hl.bind(` calls (workspace loop counts ×10).

### Phase 3 — Monitors, rules, env, startup, laptop
1. Translate the remaining six files per §5.
2. `ENVariables.conf`: confirm the Lua env API on the wiki's Environment Variables page
   (under Advanced-and-Cool) and translate; keep the commented NVIDIA/VM blocks as Lua
   comments.
   → verify: parse checks; `nix eval` toplevel still passes.

### Phase 4 — First live run (dual-tree)
1. `make rebuild` (ships both trees; `.lua` present ⇒ next Hyprland start uses Lua).
2. Log out/in (or reboot) — the startup-only precedence check requires a restart, and
   the display-manager autologin makes this cheap.
3. Diff behavior against Phase 0 snapshots: `hyprctl binds -j | jq length`,
   `hyprctl monitors -j`, `hyprctl workspacerules -j`; walk the interactive checklist:
   scratchpads (yazi/todo/quick-note + pypr term/zoom), waybar toggle, screenshots,
   volume/brightness keys, `jvf-theme-switch light && jvf-theme-switch dark`
   (colors must change live — proves `hyprctl reload` + `colors.lua` path),
   lock screen, GameMode.sh, layout switch bind.
4. Rollback if broken: delete `~/.config/hypr/hyprland.lua` and restart Hyprland
   (falls back to the untouched `.conf` tree), fix, iterate. Emergency binds
   (SUPER+Q/R/M) cover the worst case.
   → verify: checklist above; no error popups on startup.

### Phase 5 — Cutover
1. Delete `hyprland.conf`, `configs/*.conf`, `UserConfigs/*.conf` (keep `00-Readme` or
   refresh it to describe the Lua layout), delete the now-unused hyprlang color template
   from `hypr.nix` if any remnant remains.
2. `make rebuild`, restart, re-run the Phase 4 checklist once more.
   → verify: `rg -l "source =" modules/desktop/hyprland/assets/hypr` returns only
   hypridle/hyprlock files; checklist green.

### Phase 6 — Housekeeping (separate commit, pre-existing issues surfaced by the survey)
1. Remove the unused `hyprland` flake input (`flake.nix:10-11`) → `nix flake lock`
   shrinks by ~10 nodes. → verify: `nix flake check`.
2. Update `modules/desktop/hyprland/AGENTS.md` (stale: mentions removed `thunar.nix`,
   omits `theme-switcher.nix`, outdated jvf.home migration note, and its "CONFIG
   NESTING GOTCHAS" section describes a configDir-flattening in `wrappers.nix` that no
   longer exists in that file) to document the Lua layout and the colors.lua contract.
3. Optional, ask before acting: delete `modules/hosts/nixos-desktop/default.nix.bak`
   and the dead `hyprlock.conf` (only `hyprlock-2k.conf` is referenced by
   `LockScreen.sh`).

## 7. Risks and gotchas

| Risk | Mitigation |
|---|---|
| `hyprctl reload` won't switch formats — startup-only precedence | Phase 4 explicitly restarts the session; dual-tree keeps rollback one file-delete away |
| Dotted option keys (`col.active_border`) silently wrong if written as nested tables | Use `["col.active_border"]` bracket syntax; grep for `col\.` in review |
| Animations/bezier + `borderangle loop` Lua syntax unverified (wiki page not yet read) | Explicit sub-task in Phase 1.3; RainbowBorders.sh depends on it |
| Env-var Lua API unverified | Explicit sub-task in Phase 3.2 |
| `hl.workspace_rule` exact field names unverified | Check Workspace Rules wiki page in Phase 3 |
| Blocking Lua in bind callbacks freezes the compositor | Translation rule: binds only ever call `hl.dsp.*`; no `io.popen`, no inline shell |
| Theme switcher writes `colors.lua` while Hyprland reads it | Same write-then-`hyprctl reload` sequence as today; `deploy_artifacts` already copies atomically enough (single `cp`), unchanged risk profile |
| Old `.conf` knowledge in scripts (e.g. anything grepping hyprland.conf) | `rg "hyprland.conf" modules/` during Phase 5 (survey found no hits outside assets, but re-check) |
| nixpkgs bump mid-migration changes Hyprland behavior | Don't run `flake-update` between Phase 1 and Phase 5 |

## 8. Explicitly out of scope

- Adopting home-manager or the HM `configType = "lua"` generator (banned architecture).
- Migrating hypridle/hyprlock/pyprland/waybar/rofi/swaync configs (different programs,
  different formats).
- Rewriting the 47 shell scripts in Lua. Candidates like RainbowBorders (a loop calling
  `hyprctl`) would make good `hl.timer` ports later, but that's a follow-up, not this
  refactor.
