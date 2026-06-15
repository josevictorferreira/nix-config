# Decisions — Waybar Pomodoro

Durable decisions made during execution of the Waybar Pomodoro plan.
2026-06-15: Completed Task 4 runtime, fallback, and notification contracts.
2026-06-15: Defined Pomodoro contract (Task 2) including Nix options, wrapper command interface, and status display semantics.
2026-06-15 15:23:21 - Task 3 Contract Completed: Waybar integration contract established. Placement after custom/hint defined. Display states and JSON output contract specified.
Mon Jun 15 03:23:29 PM -03 2026 - Task 1: Baseline audit complete. Strategy defined.
2026-06-15T19:10Z - Task 5: Implemented programs-pomodoro as a single `pomodoro-core` script (pkgs.writeShellScriptBin to avoid shellcheck quoting friction) dispatched by subcommand, exposed as three jvf.wrappers program entries with `command` set: pomodoro-waybar-status/pomodoro-toggle/pomodoro-reset — matching Task 6 assets exactly. libnotify pinned onto wrapper PATH so notify-send is always present at runtime.

2026-06-15T21:00Z - Task 7: Activated programs-pomodoro by importing it into the  list in . Verified evaluation with 25 returning 25.

2026-06-15T21:00Z - Task 7: Activated programs-pomodoro by importing it into the  list in . Verified evaluation with 25 returning 25.
2026-06-15T21:00Z - Task 7: Activated programs-pomodoro by importing it into the `nixosAspects` list in `modules/roles/desktop.nix`. Verified evaluation with `nix eval .#nixosConfigurations.nixos-desktop.config.jvf.programs.pomodoro.durationMinutes` returning 25.