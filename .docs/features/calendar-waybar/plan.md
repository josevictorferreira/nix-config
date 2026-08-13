# Waybar Calendar Integration Plan

Status: proposal (2026-08-11)
Scope: surface real Google Calendar events in the Waybar clock hover tooltip, replacing the
built-in `clock` module with a script-backed `custom/calendar` module.

---

## 1. The blocker, and why the clock module can't do this

The `{calendar}` in the current tooltip is computed **inside Waybar** from the system clock.
It has no notion of events and exposes no hook to inject any.

From `man 5 waybar-clock` on this machine (Waybar **v0.15.0**):

```
FORMAT REPLACEMENTS
    • {calendar}      Current month calendar
    • {tz_list}       List of time in the rest timezones
    • {ordinal_date}  The current day in (English) ordinal form
```

That is the complete list. The `clock` module has no `exec`, no `return-type`, and no
ICS/CalDAV support of any kind. **There is no way to get events into that specific tooltip.**

### 1.1 What does work

Waybar `custom/*` modules accept `"return-type": "json"` and read a `tooltip` field from the
script's stdout, rendering it as **Pango markup**. A script can therefore emit the month grid
*and* real events. The hover-the-time UX is unchanged.

Two working precedents already exist in this repo:

| Module | Location | Note |
|---|---|---|
| `custom/weather` | `assets/waybar/ModulesCustom:8` | script-driven multi-line tooltip |
| `custom/pomodoro` | `assets/waybar/ModulesCustom:215` | owned by this repo, Nix-built wrappers |

### 1.2 Incidental finding — the `actions` block is dead config

In `assets/waybar/Modules`, `"clock"` closes on line **129**, and `"actions"` opens on line
**130** as a *sibling*, not nested inside the clock object:

```jsonc
"clock": {
    ...
    "calendar": { ... }
},                          // <- line 129, clock closes here
"actions": {                // <- line 130, top-level; clock never reads this
    "on-click-right": "mode",
    "on-scroll-up": "shift_up",
    ...
},
```

Waybar's clock reads actions from its **own** module config object, so the right-click
mode-switch and scroll-to-change-month are currently **inert** (an upstream KooL dotfiles
quirk, not something introduced here).

This matters for the decision: moving to a custom module **loses nothing that currently
functions**.

---

## 2. Chosen approach

Decided 2026-08-11:

- **Provider:** Google Calendar
- **Method:** read-only secret-ICS fetch (no OAuth, no daemon, no Google Cloud project)

The alternative — full CalDAV two-way sync via `vdirsyncer` + `khal` — is the upgrade path if
write access or offline speed is wanted later. It costs a systemd user timer, a sops app
password, and vdirsyncer config. Deliberately deferred.

### 2.1 Architecture

```
                        ┌─ stale? ──→ setsid -f calendar-refresh ─┐
                        │             (python: fetch + render)     │
waybar (interval: 1) ───┤                                          ↓
  exec calendar-        │                            ~/.cache/waybar-calendar/
  waybar-status ────────┴─ read cache ──→ JSON            tooltip.pango
     (bash, ~2ms)          {"text": "󰃭 14:32:07",         (atomic mv)
                            "tooltip": "<grid>\n<events>"}      ↑
                                                        sops: google_calendar_ics_url
```

**`calendar-waybar-status`** — bash, `pkgs.writeShellScriptBin`. Formats the time with `date`,
cats the cached tooltip, emits one line of JSON. If the cache is older than 15 min it detaches
a refresh and serves the stale copy meanwhile. **Never blocks on network.**

**`calendar-refresh`** — Python, `pkgs.python3.withPackages (ps: [ ps.icalendar
ps.recurring-ical-events ])`. Reads the ICS URL from the sops path, fetches, expands
recurrences over the next N days, renders the Pango tooltip, writes temp + `mv`.

### 2.2 Why the work splits into two binaries

1. **Cost.** The clock is `%H:%M:%S` at `interval: 1`, so the exec runs ~86,400×/day. A Python
   interpreter per second is real CPU for nothing. The fast path stays pure bash.
2. **The wrappers contract.** One `jvf.wrappers…programs.<key>` produces exactly one binary
   named `<key>`. Two commands necessarily means two keys — the same shape as
   `pomodoro-waybar-status` / `pomodoro-toggle`.

### 2.3 Why Python, not bash/awk, for the ICS parse

Three things in every Google Calendar feed break line-oriented parsing:

| Hazard | Effect on a naive parser |
|---|---|
| **Line folding** — ICS wraps at 75 octets with a leading space | `grep SUMMARY` truncates event titles mid-word |
| **RRULE expansion** — a weekly standup appears **once** with a recurrence rule | Event shows on the wrong date, or never. Most calendars are *mostly* recurring events, so this is the dominant failure. |
| **TZID handling** — `DTSTART;TZID=America/Sao_Paulo` vs floating vs UTC `Z` | Events render at the wrong hour |

`recurring-ical-events` handles RRULE expansion including `EXDATE` and `RECURRENCE-ID`
overrides (a single instance of a series moved to another day). All libraries are present in
the current nixpkgs pin:

| Package | Version |
|---|---|
| `python3Packages.icalendar` | 7.2.0 |
| `python3Packages.recurring-ical-events` | 3.9.0 |
| `khal` / `vdirsyncer` / `gcalcli` | 0.14.0 / 0.20.0 / 4.5.1 (unused by this plan; noted for the CalDAV upgrade path) |

### 2.4 Two non-obvious runtime requirements

- **`setsid -f` on the detached refresh is mandatory, not cosmetic.** Waybar kills its own
  child processes on reload — the exact failure that previously broke the theme switcher's
  `on-click` mid-run. A refresh spawned as a direct child of the Waybar exec dies with it.
- **Absolute paths in the Modules JSON.** Waybar's startup PATH does not include
  `~/.local/bin`; bare command names fail to resolve. `custom/pomodoro` already works around
  this with `$HOME/.local/bin/...`, and `modules/wrappers.nix:129-130` confirms wrappers are
  symlinked into `~/.local/bin/<programName>`. Follow the same convention.

### 2.5 Secret handling

The Google secret ICS address embeds a private token that grants read access to the entire
calendar. It must not land in the nix store (world-readable) or the asset tree (git-tracked).

Register through the existing mechanism in `modules/secrets/environment.nix`:

```nix
jvf.secrets.environment.keys.google_calendar_ics_url = true;
```

`calendar-refresh` reads `config.sops.secrets.google_calendar_ics_url.path` **directly**,
rather than the exported uppercase env var — the refresher runs detached from Waybar and
cannot rely on a shell export having happened.

---

## 3. Files to change

| # | File | Change |
|---|---|---|
| 1 | `modules/programs/waybar-calendar/default.nix` | **New.** Aspect `programs-waybar-calendar`: both scripts, 2 wrapper keys, registers the sops key. Darwin export is a no-op stub (Waybar is Linux-only — same pattern as `programs-steam`). |
| 2 | `modules/desktop/hyprland/assets/waybar/Modules` | **Add** a `"custom/calendar"` block. Leave the existing `"clock"` block in place, untouched. |
| 3 | `modules/desktop/hyprland/assets/waybar/config` | Swap `"clock"` → `"custom/calendar"` in `modules-center`. |
| 4 | `modules/roles/desktop.nix` | Import `programs-waybar-calendar`, next to `programs-pomodoro`. |
| 5 | `modules/desktop/hyprland/assets/waybar/style.css` | *Conditional* — if it targets `#clock`, add a matching `#custom-calendar` rule so nothing shifts visually. |

### 3.1 Placement rationale

- Leaving `"clock"` **defined but unreferenced** makes the revert a one-word edit in `config`.
- The new aspect goes in `roles-desktop`, not inside `waybar.nix`: dendritic rules forbid leaf
  modules importing other leaf modules. `programs-pomodoro` sits in `roles-desktop` for
  exactly this reason and is the direct precedent — a custom Waybar module owned by this repo.
- `assets/waybar/` is a **raw asset tree**, copied wholesale by `waybar.nix` via
  `jvf.home` (`kind = "dir"; mode = "copy"`, `waybar.nix:115-123`). Module definitions are
  edited as JSON in the
  asset tree, consistent with the "raw upstream-style files" convention in
  `modules/desktop/hyprland/AGENTS.md`.

### 3.2 Tooltip content

Month grid (Python `calendar` stdlib, today marked) + separator + upcoming events grouped by
day, reusing the existing color codes from the current clock config so it looks native:

| Element | Color |
|---|---|
| months | `#ffead3` |
| weekdays | `#ffcc66` |
| today | `#ff6699` (bold, underlined) |
| days | `#ecc6d9` |
| weeks | `#99ffdd` |

---

## 4. Verification

| # | Step | Pass condition |
|---|---|---|
| 1 | `nix eval .#nixosConfigurations.nixos-desktop.config.system.build.toplevel` | resolves to a `.drv` |
| 2 | `make rebuild` | completes; `~/.local/bin/calendar-*` exist |
| 3 | `calendar-refresh` by hand | cache file written, non-empty |
| 4 | `calendar-waybar-status \| jq .` | valid JSON; `tooltip` non-empty |
| 5 | `pkill waybar && setsid -f waybar` | single bar, no module-load errors |
| 6 | Hover the clock | month grid + real events visible |

**Step 5 detail:** use `pkill waybar`, **not** `pkill -x waybar`. NixOS wraps the binary as
`.waybar-wrapped`, so `-x` misses it and leaves a duplicate bar running.

Before rebuild, `git add` the new module file — flakes use pure eval and untracked files are
invisible.

---

## 5. Known limitations

Accepted consequences of the read-only ICS approach, not defects to fix later:

- **Read-only.** No adding or editing events. The CalDAV path is the upgrade for write access.
- **Google caches the ICS feed aggressively.** The secret-address feed can lag real calendar
  changes by minutes to hours. This is Google's server-side behavior; no client-side polling
  interval changes it. If near-real-time is required, this approach will not deliver it.
- **A 15-minute local cache** adds its own delay on top of the above.
- **URL rotation breaks it.** Using Google's "reset private URLs" invalidates the secret
  address until sops is updated.
- **The current calendar is `"mode": "year"`** with 3-month columns. A full year grid *plus* an
  events list is very cramped; the plan switches to month view. Flagged because it is a
  visible change to existing behavior, not purely an addition.

### 5.1 Pre-flight risk

A **Google Workspace admin can disable secret ICS addresses** org-wide. If the target calendar
belongs to `jose.ferreira@agrosmart.com.br` and that policy is enforced, this entire approach
is blocked and the work would have to move to OAuth (`gcalcli`) or the Graph-style path. Worth
confirming before implementation starts. A personal Gmail calendar has no such restriction.

---

## 6. Prerequisite before implementation

The secret ICS URL, obtained from:

> Google Calendar → **Settings** → select the calendar → **Integrate calendar** →
> *Secret address in iCal format* (ends in `/basic.ics`)

Add it to the sops secrets file under `google_calendar_ics_url`. It should not be pasted into
a chat transcript or committed anywhere.

All code can be written before the secret exists — the script reads the sops path and will
fail cleanly with a "secret not configured" tooltip until it is populated.
