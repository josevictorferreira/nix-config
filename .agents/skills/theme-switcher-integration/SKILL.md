---
name: "theme-switcher-integration"
description: >
  Gotchas for anything that integrates with jvf-theme-switch (the dark/light
  toggle) in THIS repo — adding app hooks, fixing apps that don't follow the
  toggle, editing kitty/theme-switcher assets. Use when: a GUI app stays light
  or dark after toggling, adding a new app to the theme switch hooks, changing
  kitty.conf settings, or touching modules/desktop/hyprland/theme-switcher.nix.
---

# Theme switcher integration gotchas

`jvf-theme-switch` (modules/desktop/hyprland/theme-switcher.nix) toggles
dark/light by deploying profile artifacts and running per-app hooks. Two
failure modes are silent and each cost a full debugging session.

## 1. The switcher overwrites kitty.conf — new settings must be allowlisted

**Rule:** Adding a non-color kitty setting requires editing **two files**:
`modules/programs/kitty/_/kitty-conf.nix` (or `default.nix` `defaultSettings`)
AND the preserve-grep allowlist in `theme-switcher.nix`:

```bash
grep -E '^(shell|allow_remote_control|remember_window_size|listen_on|map) ' ...
```

**Why:** the switcher overwrites `~/.config/kitty/kitty.conf` wholesale from
the generated theme profile (colors+fonts only), then re-appends only lines
matching the allowlist. A setting added to `defaultSettings` but missing from
the allowlist survives a rebuild, then **silently disappears on the next theme
switch** — a delayed-action bug that looks unrelated when it fires. This is
how `remember_window_size no` (the Kitty-fights-Hyprland-tiling fix, commit
`36b2f4ad`) had to be wired.

**Verify:** run `jvf-theme-switch dark && jvf-theme-switch light` (or toggle
twice), then `grep remember_window_size ~/.config/kitty/kitty.conf` — the
setting must still be there.

## 2. Any bar on-click that reloads Waybar must detach: `setsid -f`

**Rule:** in Waybar `on-click` handlers that end up reloading/restarting
Waybar itself, launch with `setsid -f` — e.g. `"on-click": "setsid -f jvf-theme-switch toggle"`.

**Why:** Waybar runs on-click commands as children of Waybar's own process
group. `jvf-theme-switch` sends `pkill -SIGUSR2 waybar` to live-reload the
bar — reloading its own parent — and the reload tears down the process tree,
**killing the switcher mid-run** ~1s later. Symptoms: hooks later in the
sequence (dconf → Brave color-scheme, btop) silently never run. The tell:
the failure happens from the Waybar button but NOT from a terminal (a
terminal child isn't Waybar's child). Evidence: failing runs' hooks.log
stopped dead at `waybar reload: ok`.

**Verify:** click the toggle, then check
`~/.local/state/jvf-theme/hooks.log` — every hook line must appear,
including the last one.

## 3. Restarting Waybar on NixOS: the comm is `.waybar-wrapped`

**Rule:** `pkill -x waybar` / `pgrep -x waybar` match NOTHING (process comm
is `.waybar-wrapped`). Use `pkill waybar` (substring), `pidof waybar`
(argv[0]), or `pkill .waybar-wrapped`. To relaunch from a keybind:
`hyprctl reload; pkill waybar; sleep 0.3; hyprctl dispatch 'hl.dsp.exec_cmd("waybar")'`.

## 4. Brave/Chromium color-scheme depends on the XDG portal — check dconf BEFORE blaming Brave

**Rule:** if Brave ignores the toggle, first check the value the hook writes:
`dconf read /org/gnome/desktop/interface/color-scheme` (must be
`'prefer-dark'`). Brave reads `color-scheme` through the Settings interface of
`xdg-desktop-portal-gtk` — which declares `UseIn=gnome` and silently refuses
to load on Hyprland unless patched (`overrideAttrs` → `UseIn=gnome;Hyprland` +
`lib.mkForce extraPortals`). No error is logged anywhere; diagnose with
`gdbus introspect --session --dest org.freedesktop.portal.Desktop --object-path /org/freedesktop/portal/desktop`
(`org.freedesktop.portal.Settings` must be listed).

## 5. Diagnosing any "app didn't follow the toggle": read hooks.log first

**Rule:** before theorizing, read `~/.local/state/jvf-theme/hooks.log` for the
failing run and compare against a manual `jvf-theme-switch dark` from a
terminal. The log shows exactly which hook ran; where it stops IS the bug
(either killed mid-run — see gotcha 2 — or the hook ordering matters).

**Verify:** `cat ~/.local/state/jvf-theme/hooks.log` after both a
button-toggle and a terminal run; diff them.

## Evidence

- Session `eb4821b5` (2026-08): Brave+btop stuck light; root cause Waybar
  child-kill; fix `setsid -f` in `assets/waybar/ModulesCustom` (current
  file confirms the fix is live).
- Session `1f009492` + commit `36b2f4ad` (Kitty `remember_window_size`):
  the kitty allowlist dance.
- Claude memories `theme-switcher-waybar-lifecycle.md`,
  `theme-switcher-kitty-operational-lines.md`, `theme-switcher-dconf-brave.md`.
