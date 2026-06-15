# Aspect: programs-pomodoro
# A minimal, daemon-free Pomodoro timer for Waybar.
#
# State is wall-clock based and transient (cache dir only): a single state file
# records start/end epoch timestamps so Waybar can recompute the countdown on
# every reload without a background process. Stale/corrupt/missing/expired state
# always degrades to idle.
#
# Three commands are exposed via jvf.wrappers (one wrapper per program key),
# matching the names the Waybar `custom/pomodoro` module already calls:
#   - pomodoro-waybar-status : prints Waybar JSON for idle/running/completed
#   - pomodoro-toggle        : start a session, or stop a running one (no notify)
#   - pomodoro-reset         : clear back to idle/default (no notify)
# Only natural completion emits a notify-send (via libnotify).
_:
let
  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.programs.pomodoro;

      pomodoroCore = pkgs.writeShellScriptBin "pomodoro-core" ''
        set -u
        export PATH=${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:$PATH

        DURATION_MINUTES=${toString cfg.durationMinutes}
        DURATION_SECONDS=$(( DURATION_MINUTES * 60 ))
        CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/pomodoro"
        STATE_FILE="$CACHE_DIR/state"
        ICON="🍅"

        ensure_dir() { mkdir -p "$CACHE_DIR"; }

        # write_state <start> <end> <status> <duration_seconds> (atomic via mv)
        write_state() {
          ensure_dir
          tmp="$(mktemp "$CACHE_DIR/state.XXXXXX")"
          printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4" > "$tmp"
          mv -f "$tmp" "$STATE_FILE"
        }

        write_idle() { write_state 0 0 idle "$DURATION_SECONDS"; }

        # fmt_mmss <seconds> -> MM:SS (clamped at 0)
        fmt_mmss() {
          total=$1
          [ "$total" -lt 0 ] && total=0
          printf '%02d:%02d' $(( total / 60 )) $(( total % 60 ))
        }

        # emit_json <text> <class> <tooltip>
        emit_json() {
          printf '{"text": "%s", "class": "%s", "tooltip": "%s", "alt": "%s"}\n' "$1" "$2" "$3" "$2"
        }

        emit_idle() {
          emit_json "$ICON $(fmt_mmss "$DURATION_SECONDS")" "idle" "Pomodoro: idle"
        }

        # read_state -> echoes "start end status duration" or returns 1 (invalid)
        read_state() {
          [ -f "$STATE_FILE" ] || return 1
          line="$(cat "$STATE_FILE" 2>/dev/null)" || return 1
          IFS='|' read -r start end st dur <<< "$line"
          case "$st" in idle|running|completed) ;; *) return 1 ;; esac
          [ -n "$start" ] && [ -n "$end" ] && [ -n "$dur" ] || return 1
          case "$start$end$dur" in *[!0-9]*) return 1 ;; esac
          echo "$start $end $st $dur"
        }

        cmd_status() {
          if ! parsed="$(read_state)"; then
            write_idle
            emit_idle
            return
          fi
          read -r start end st dur <<< "$parsed"
          now="$(date +%s)"
          case "$st" in
            idle)
              emit_json "$ICON $(fmt_mmss "$dur")" "idle" "Pomodoro: idle"
              ;;
            running)
              # Illogical timestamps (future start, end before start) -> idle.
              if [ "$end" -lt "$start" ] || [ "$start" -gt "$now" ]; then
                write_idle
                emit_idle
                return
              fi
              if [ "$end" -le "$now" ]; then
                # Natural completion: flip to completed once, notify once.
                write_state "$start" "$end" completed "$dur"
                notify-send "Pomodoro Complete" "Time is up!" 2>/dev/null \
                  || echo "pomodoro: notify-send failed" >&2
                emit_json "$ICON Done" "completed" "Pomodoro: complete"
              else
                emit_json "$ICON $(fmt_mmss $(( end - now )))" "running" "Pomodoro: running"
              fi
              ;;
            completed)
              emit_json "$ICON Done" "completed" "Pomodoro: complete"
              ;;
          esac
        }

        cmd_toggle() {
          now="$(date +%s)"
          if parsed="$(read_state)"; then
            read -r start end st dur <<< "$parsed"
            if [ "$st" = "running" ] && [ "$end" -gt "$now" ] \
              && [ "$end" -ge "$start" ] && [ "$start" -le "$now" ]; then
              # Manual stop -> idle, no notification.
              write_idle
              cmd_status
              return
            fi
          fi
          # Start a fresh session.
          write_state "$now" "$(( now + DURATION_SECONDS ))" running "$DURATION_SECONDS"
          cmd_status
        }

        cmd_reset() {
          # Reset to idle, no notification.
          write_idle
          cmd_status
        }

        case "''${1:-status}" in
          status) cmd_status ;;
          toggle) cmd_toggle ;;
          reset)  cmd_reset ;;
          *)      cmd_status ;;
        esac
      '';
    in
    {
      options.jvf.programs.pomodoro = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username to install the Pomodoro commands for.";
        };

        durationMinutes = lib.mkOption {
          type = lib.types.ints.positive;
          default = 25;
          description = "Pomodoro work session length, in minutes.";
        };
      };

      config = {
        jvf.wrappers.users.${cfg.username}.programs = {
          "pomodoro-waybar-status".command = "${pomodoroCore}/bin/pomodoro-core status";
          "pomodoro-toggle".command = "${pomodoroCore}/bin/pomodoro-core toggle";
          "pomodoro-reset".command = "${pomodoroCore}/bin/pomodoro-core reset";
        };
      };
    };
in
{
  flake.modules.nixos.programs-pomodoro = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-pomodoro = mkConfig { isDarwin = true; };
}
