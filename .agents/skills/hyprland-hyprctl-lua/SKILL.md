---
name: "hyprland-hyprctl-lua"
description: >
  Gotchas for any script, keybind, Waybar on-click, or Nix module that drives
  Hyprland via `hyprctl` in THIS repo (compositor config is Lua since >= 0.55).
  Use when: writing or editing `hyprctl dispatch/keyword/eval` calls, debugging
  "hyprctl did nothing" / a keybind or bar button that silently fails, driving
  Hyprland from SSH/systemd/tmux contexts, or translating legacy hyprlang
  hyprctl syntax. Not for editing the Lua config itself (see
  modules/desktop/hyprland/AGENTS.md).
---

# hyprctl under a Hyprland Lua config

Since the Lua cutover (Hyprland >= 0.55; this repo runs it), `hyprctl` is
**not** format-independent. ~45 call sites across this repo broke at once and
the breakage was silent. Every rule below comes from a live debugging session
on this machine.

## 1. `hyprctl dispatch <args>` is evaluated as Lua — legacy syntax fails SILENTLY

**Rule:** Write dispatch args as Lua. `hyprctl dispatch exec waybar` does
nothing: the error (`')' expected near 'waybar'`) goes to hyprctl's *stdout*,
which keybinds, Waybar `on-click`, and swaync all discard. Nothing appears in
the Hyprland log either — the only trace is a missing `[executor] Executing`
line.

**Why:** Aug 2026 session debugging why Waybar vanished after the cutover —
every legacy-syntax call site looked correct but was dead.

**Verify:** Run the command from a terminal and read stdout:
```bash
hyprctl dispatch 'hl.dsp.workspace.toggle_special("yazi")'
# and check the executor picked it up in the compositor log
```

## 2. `hl.dsp.dpms` takes a TABLE — a string silently toggles

**Rule:** `hyprctl dispatch 'hl.dsp.dpms({ action = "off" })'`. The string
form `dpms("off")` does not error — it ignores the argument and TOGGLES dpms
per monitor (source: `hlDpms` → `tableToggleAction`). This bit lights-off,
ResumeFromIdle.sh, and hypridle.conf before being fixed 2026-09-23.

**Verify:** `hyprctl dispatch 'hl.dsp.dpms({ action = "off" })'` then
`hyprctl monitors` — every monitor must report off; a toggle leaves one on.

## 3. `keyword` and `setprop` are gone; use `eval` + `hl.*` Lua

**Rule:**
- `hyprctl keyword general:blur:size 2` → rejected ("can't work with
  non-legacy parsers. Use eval."). Replacement:
  `hyprctl eval 'hl.config({decoration={blur={size=2}}})'` — colon paths
  become nested tables; gradients need `colors = {"A","B"}` + `angle`.
- `hyprctl setprop ...` → "unknown request". Use
  `hl.dsp.window.set_prop({prop=…, value=…})` (defaults to active window).
- Still fine unchanged: `reload`, `monitors`, `clients`, `activewindow`,
  `getoption`, `devices`, `binds`, `switchxkblayout`.

**Verify:** The eval returns `ok` only; wrap values in `error(...)` to read
them back: `hyprctl eval 'error(hl.getoption("general:border_size"))'`.

## 4. NEVER probe unknown dispatchers against the live session

**Rule:** `hl.dsp.exit()` ignores its arguments — probing it with a bogus key
(`{__bogus=1}`) does NOT raise a validation error, it **exits the compositor
and logs the user out**. To discover dispatcher names, enumerate keys instead
of calling them:

```bash
hyprctl eval 'local t={} for k in pairs(hl.dsp) do t[#t+1]=k end table.sort(t) error(table.concat(t,", "))'
```

**Why:** Discovered the hard way while mapping the API; exit cost a login
session.

**Verify:** Enumeration prints; the session is still alive.

## 5. hyprctl from SSH / systemd / tmux: resolve `HYPRLAND_INSTANCE_SIGNATURE` yourself

**Rule:** hyprctl locates the compositor via `HYPRLAND_INSTANCE_SIGNATURE`,
which only processes started inside Hyprland inherit. From SSH (or any
non-Hyprland parent) it fails with `HYPRLAND_INSTANCE_SIGNATURE not set!` —
and if the script redirects to `/dev/null` (lights-off did), the failure is
invisible. Pattern already in `modules/system/lights-off.nix`:

```bash
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  hypr_dir="/run/user/$(id -u)/hypr"
  HYPRLAND_INSTANCE_SIGNATURE=$(ls -t "$hypr_dir" 2>/dev/null | head -n1)
  export HYPRLAND_INSTANCE_SIGNATURE
fi
```

**Why:** Oct 2026 — "lights off script is not turning off my monitors" over
SSH; the lockscreen (hyprlock over autologin Hyprland) masked that Hyprland
was running fine and the env var was the problem.

**Verify:** `hyprctl monitors` returns data from the SSH shell.

## 6. Quoting through wrapper layers

Each layer eats one level of quotes. Verified working forms:
- Waybar/swaync JSON: `"hyprctl dispatch 'hl.dsp.focus({workspace = \"e+1\"})'"`
- Shell with a variable: `hyprctl dispatch "hl.dsp.focus({window = 'class:^($VAR)$'})"`
- yazi keymap (three layers) — use a Lua long bracket, which needs no quotes:
  `"shell 'hyprctl dispatch \"hl.dsp.workspace.toggle_special([[yazi]])\"'"`

**Verify:** `hyprctl dispatch` from a terminal with the exact nested string
before wiring it into the asset file.

## 7. Verify config offline — but know its blind spots

`Hyprland --verify-config -c <ABSOLUTE>/path/hyprland.lua` is a semantic
checker (unknown keys, bad types, invalid keysyms, bad dispatcher args) — use
it instead of reloading the live compositor. Blind spots found by probing:
**window-rule fields are NOT validated** (`opacity = "banana"` passes), and
**bind option tables are NOT validated** (`{ locke = true }` passes) — check
those against the stubs in `/run/current-system/sw/share/hypr/stubs`.

**Verify:** `Hyprland --verify-config -c "$PWD/modules/desktop/hyprland/assets/hypr/hyprland.lua"` → exit 0 + "config ok".

## Evidence

- Session `a6db7b2e` (2026-08-10, 1476 lines): Lua cutover fallout, dpms
  toggle bug, API mapping (Claude Code project store).
- Session `2e6dca8a` (2026-10-01): SSH `HYPRLAND_INSTANCE_SIGNATURE` failure
  in lights-off; fix landed in `modules/system/lights-off.nix`.
- Claude memory `hyprctl-under-lua-config.md` + `hyprland-lua-verification.md`
  (verified replacement table, exit() hazard, verify-config blind spots).
- Current call sites: `modules/system/lights-off.nix`,
  `assets/hypr/scripts/{ResumeFromIdle,ToggleTodo,ToggleQuickNote}.sh`,
  `modules/programs/yazi/default.nix`, `hypridle.conf`.
