# Aspect: desktop-hyprland-theme-switcher (NixOS only)
# Runtime theme switcher CLI: jvf-theme-switch {light|dark|auto|status}
# Exposes script via jvf.wrappers packages.
# Runtime state lives in ~/.local/state/jvf-theme/ (never mutates Nix store).
#
# Resume convergence: best-effort hook runs jvf-theme-switch auto after suspend.
# Failure mode: if resume detection unavailable, boot/login + scheduled timers
# still converge to the correct theme. Resume hook warns and no-ops on failure.
_:
let
  switcherScript =
    { pkgs }:
    pkgs.writeScriptBin "jvf-theme-switch" ''
            #!/usr/bin/env bash
            set -euo pipefail

            STATE_DIR="''${JFV_THEME_STATE_DIR:-$HOME/.local/state/jvf-theme}"
            PROFILES_DIR="''${JFV_THEME_PROFILES_DIR:-$HOME/.local/share/jvf-theme/profiles}"
            LOG_FILE="$STATE_DIR/hooks.log"
            WARN_FILE="$STATE_DIR/hooks.warn"

            usage() {
              cat >&2 <<'HELP'
      Usage: jvf-theme-switch {light|dark|auto|status} [--verbose]
             jvf-theme-switch --help

      Commands:
        light   Switch to light profile and stay there (manual override)
        dark    Switch to dark profile and stay there (manual override)
        auto    Follow schedule: light 06:00-11:59, dark 12:00-05:59
        status  Show current mode and profile
                Use --verbose for schedule, last switch time, warnings, and limitations

      Notes:
        - Manual light/dark overrides stick until auto is run again.
        - All reload hooks are safe and best-effort: failures are logged, not fatal.
        - Live retheming works for Hyprland, Waybar, Kitty, GTK (via gsettings),
          and Btop. Other apps may need a restart.
      HELP
              exit 1
            }

            warn() { echo "warn: $*" >> "$WARN_FILE"; }
            log()  { echo "$(date -Iseconds) $*" >> "$LOG_FILE"; }

            # ── Reload hooks (best-effort, failure-tolerant) ────────────────
            run_hooks() {
              local profile_dir="$1"
              rm -f "$WARN_FILE"
              : > "$LOG_FILE"

              # Hyprland
              if command -v hyprctl >/dev/null 2>&1; then
                hyprctl reload >/dev/null 2>&1 && log "hyprctl reload: ok" || warn "hyprctl reload failed"
              else
                warn "hook: hyprctl not available"
              fi

              # Waybar
              if command -v waybar >/dev/null 2>&1; then
                if pgrep -x waybar >/dev/null 2>&1; then
                  kill -SIGUSR2 "$(pgrep -x waybar | head -1)" 2>/dev/null && log "waybar reload: ok" || warn "waybar SIGUSR2 failed"
                else
                  warn "hook: waybar not running"
                fi
              else
                warn "hook: waybar not available"
              fi

              # Kitty remote
              if command -v kitty >/dev/null 2>&1; then
                local kitty_conf="$profile_dir/terminals/kitty.conf"
                if [ -S /tmp/kitty-remote ]; then
                  if [ -f "$kitty_conf" ]; then
                    kitty @ --to unix:/tmp/kitty-remote set-colors --all "$kitty_conf" 2>/dev/null \
                      && log "kitty set-colors: ok" || warn "kitty set-colors failed"
                  else
                    warn "hook: kitty.conf not found in profile"
                  fi
                else
                  warn "hook: kitty remote socket not available"
                fi
              else
                warn "hook: kitty not available"
              fi

              # GTK
              if command -v gsettings >/dev/null 2>&1; then
                local gtk_scheme
                case "$(cat "$STATE_DIR/mode" 2>/dev/null)" in
                  light) gtk_scheme="prefer-light" ;;
                  *)     gtk_scheme="prefer-dark" ;;
                esac
                gsettings set org.gnome.desktop.interface color-scheme "$gtk_scheme" 2>/dev/null \
                  && log "gsettings: ok" || warn "gsettings set failed"
              else
                warn "hook: gsettings not available"
              fi

              # Btop — symlink theme file if runtime state exists
              if [ -d "$profile_dir/btop" ]; then
                local btop_theme
                btop_theme=$(find "$profile_dir/btop" -name '*.theme' -type f 2>/dev/null | head -1)
                if [ -n "$btop_theme" ]; then
                  local btop_themes_dir="$HOME/.config/btop/themes"
                  mkdir -p "$btop_themes_dir"
                  ln -sf "$btop_theme" "$btop_themes_dir/$(basename "$btop_theme")" 2>/dev/null \
                    && log "btop theme symlink: ok" || warn "btop theme symlink failed"
                fi
              fi
            }

            # ── Switch commands ──────────────────────────────────────────────
            do_switch() {
              local profile="$1"
              local mode="$2"
              mkdir -p "$STATE_DIR"
              echo "$mode" > "$STATE_DIR/mode"
              ln -sfn "$PROFILES_DIR/$profile" "$STATE_DIR/current"
              date +%s > "$STATE_DIR/last-switch"
              run_hooks "$PROFILES_DIR/$profile"
              echo "Mode set to $mode"
            }

            do_auto() {
              local hour="''${JFV_THEME_FAKE_HOUR:-$(date +%H)}"
              hour=$((10#$hour))
              local profile
              if [ "$hour" -ge 6 ] && [ "$hour" -lt 12 ]; then
                profile="light"
              else
                profile="dark"
              fi
              mkdir -p "$STATE_DIR"
              echo "auto" > "$STATE_DIR/mode"
              ln -sfn "$PROFILES_DIR/$profile" "$STATE_DIR/current"
              date +%s > "$STATE_DIR/last-switch"
              run_hooks "$PROFILES_DIR/$profile"
              echo "auto: selected $profile profile"
              echo "Mode set to auto"
            }

            do_status() {
              local mode
              mode=$(cat "$STATE_DIR/mode" 2>/dev/null || echo "unknown")
              local target
              target=$(readlink "$STATE_DIR/current" 2>/dev/null || echo "none")
              local profile
              profile=$(basename "$target" 2>/dev/null || echo "none")

              if [ "''${1:-}" = "--verbose" ]; then
                local last
                last=$(cat "$STATE_DIR/last-switch" 2>/dev/null || echo "never")
                local warnings="none"
                if [ -f "$WARN_FILE" ]; then
                  warnings=$(cat "$WARN_FILE" | tr '\n' '; ' | sed 's/; $//')
                fi
                echo "Mode: $mode"
                echo "Profile: $profile"
                echo "Current target: $target"
                echo "Schedule: light 06:00-11:59, dark 12:00-05:59"
                echo "Last switch: $last"
                echo "Reload warnings: $warnings"
                echo ""
                echo "Limitations:"
                echo "  - Running GTK/Qt apps may need restart for full theme change"
                echo "  - KDE Plasma/GNOME Shell/Tk live theming not supported"
                echo "  - Wallpaper switching deferred (see wallust)"
                echo "  - Qt5ct/Qt6ct color schemes deferred (hardcoded Catppuccin)"
              else
                echo "Mode: $mode"
                echo "Profile: $profile"
              fi
            }

            # ── Main dispatch ────────────────────────────────────────────────
            verb="''${1:-}"
            case "$verb" in
              --help|-h) usage ;;
              light)  do_switch light light ;;
              dark)   do_switch dark dark ;;
              auto)   do_auto ;;
              status) do_status "''${2:-}" ;;
              *)      usage ;;
            esac
    '';

in
{
  flake.modules.nixos.desktop-hyprland-theme-switcher =
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      username = config.jvf.core.username;
      switcherPkg = switcherScript { inherit pkgs; };
    in
    {
      options.jvf.desktop.hyprland.themeSwitcher = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Username for theme switcher wrapper.";
        };
      };

      config = {
        jvf.wrappers.users.${username}.programs.jvf-theme-switch = {
          packages = [ switcherPkg ];
        };

        # Scheduled theme convergence: auto-switch at 06:00 and 12:00 local time.
        systemd.user.services.jvf-theme-switcher = {
          description = "Scheduled theme auto-switch";
          after = [ "graphical-session.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${switcherPkg}/bin/jvf-theme-switch auto";
          };
        };

        systemd.user.timers.jvf-theme-switcher = {
          description = "Timer for scheduled theme auto-switch";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*-*-* 06,12:00:00";
            Persistent = true;
          };
        };

        # Best-effort resume convergence: re-evaluate theme after suspend.
        # If sleep/resume targets are unavailable (e.g. desktop-only), this
        # service simply won't start — boot/login + timers are the fallback.
        systemd.user.services.jvf-theme-switcher-resume = {
          description = "Re-evaluate theme after resume from suspend";
          after = [ "suspend.target" ];
          wantedBy = [ "suspend.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${switcherPkg}/bin/jvf-theme-switch auto";
            ExecStop = "/bin/true";
          };
        };
      };
    };
}
