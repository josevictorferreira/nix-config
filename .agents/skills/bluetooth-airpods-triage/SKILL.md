---
name: "bluetooth-airpods-triage"
description: >
  Gotchas for debugging Bluetooth device problems (AirPods/earbuds/reconnect
  loops/failed connects) on THIS machine (zeh-pc, RTL8761BU dongle). Use when:
  AirPods or earbuds connect then drop after ~30-60s, `br-connection-aborted-by-local`
  errors, or any "why did my Bluetooth disconnect" investigation. Not for
  new-device pairing setup.
---

# Bluetooth / AirPods reconnect-loop triage (zeh-pc)

This exact symptom family has been investigated **three separate times**
(May, Sep, Oct 2026) and each had a DIFFERENT root cause. The first
diagnostic decision is: **who ends the connection?** Everything else follows
from that.

## 1. Get the HCI disconnect reason without root — gdbus, not btmon

**Rule:** `sudo` needs a password on this machine, so `btmon` is usually
unavailable. Get the disconnect reason unprivileged:

```bash
gdbus monitor --system --dest org.bluez \
  --object-path /org/bluez/hci0/dev_<MAC_underscored> \
  | grep --line-buffered -E "Device1.Disconnected|Connected"
```

The `Device1.Disconnected (reason, message)` line names the killer:
`org.bluez.Reason.Local` vs `org.bluez.Reason.Remote`.

**Verify:** leave it running while the device cycles; capture one full
connect → drop cycle.

## 2. The three known causes, mapped by symptom

| Who drops | Cycle | Root cause | Fix (already in repo) |
|---|---|---|---|
| **Local abort** — `br-connection-aborted-by-local` | random / on connect | linux-zen compiles `btusb` with `enable_autosuspend=Y` (mainline: N); the RTL8761BU dongle stops answering once suspended | `boot.extraModprobeConfig = "options btusb enable_autosuspend=0"` in `modules/hardware/bluetooth.nix` (commit `b7c70fcc`) |
| **Local, ~40s loop** | exactly ~40s | `ControllerMode=dual` + Experimental exposes the Ranging Profile BlueZ can't service | `ControllerMode = "bredr"` in `bluetooth.nix` (commit `fc10da6c`) |
| **Remote (0x13)** "terminated by remote user" | ~30-60s after A2DP fd ready | The AirPods themselves — Apple auto-switch stealing them back to the nearby iPhone. The `DeviceID=bluetooth:004C:...` vendor spoof (needed by librepods) puts the PC into Apple's switching arbitration | **No Nix fix.** iPhone → Settings → Bluetooth → AirPods (i) → Connect to This iPhone → "When Last Connected to This iPhone". Killing librepods does NOT stop these drops |

**Verify:** match the gdbus reason + cycle timing to a row, apply that row's
fix, then re-run the monitor for 5+ minutes with no drops.

## 3. linux-zen module defaults are invisible — check /sys, not the config

**Rule:** zen kernel compiles module parameters as built-in defaults; they do
NOT appear in any config file. To see the effective value read sysfs:
`cat /sys/module/btusb/parameters/enable_autosuspend` (`Y` here = the bug
is live). Generalizes to any "why is this module behaving differently on zen"
question: check `/sys/module/<mod>/parameters/` FIRST.

**Verify:** after rebuild, the sysfs file must read `N`.

## 4. Both PC-side fixes live in `modules/hardware/bluetooth.nix` — don't re-diagnose

The autosuspend fix and BR/EDR-only mode are committed and active
(verified present in the current file). The Oct 2026 session re-verified both
were live before concluding the cause was the iPhone. When this symptom
recurs, check these are still in place, then go straight to the gdbus
reason.

**Verify:** `grep -E "ControllerMode|enable_autosuspend" modules/hardware/bluetooth.nix`
shows both; `cat /sys/module/btusb/parameters/enable_autosuspend` → `N`.

## Evidence

- Session `c24c6fe3` (2026-05): `br-connection-aborted-by-local` → autosuspend
  fix (commit `b7c70fcc`).
- Session `1b3a0e3a` (2026-09): noise-cancellation investigation.
- Session `413b7e24` (2026-10-21): gdbus reason=Remote → iPhone auto-switch
  verdict; wrote `bluetooth-airpods-reconnect.md` memory.
- Commit `fc10da6c`: `ControllerMode=bredr` fix.
- Current repo state confirms both fixes live in `modules/hardware/bluetooth.nix`.
