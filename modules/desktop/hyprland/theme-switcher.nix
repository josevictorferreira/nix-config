# Aspect: desktop-hyprland-theme-switcher (NixOS only)
# Runtime theme switcher CLI: jvf-theme-switch {light|dark|toggle|auto|status}
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
    pkgs.writeShellScriptBin "jvf-theme-switch" ''
            set -euo pipefail

            # Waybar click handlers launch this with a minimal PATH, so the
            # reload hooks (dconf, find, sed, cp…) silently no-op. Pin the core
            # tools from the Nix store; keep $PATH for session tools (hyprctl, kitty).
            export PATH="${
              pkgs.lib.makeBinPath [
                pkgs.coreutils
                pkgs.findutils
                pkgs.gnused
                pkgs.gnugrep
                pkgs.dconf
              ]
            }:$PATH"

            STATE_DIR="''${JFV_THEME_STATE_DIR:-$HOME/.local/state/jvf-theme}"
            PROFILES_DIR="''${JFV_THEME_PROFILES_DIR:-$HOME/.local/share/jvf-theme/profiles}"
            LOG_FILE="$STATE_DIR/hooks.log"
            WARN_FILE="$STATE_DIR/hooks.warn"

            usage() {
              cat >&2 <<'HELP'
      Usage: jvf-theme-switch {light|dark|toggle|auto|status} [--verbose]
             jvf-theme-switch --help

      Commands:
        light   Switch to light profile and stay there (manual override)
        dark    Switch to dark profile and stay there (manual override)
        toggle  Switch between light and dark profiles (manual override)
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

              # ── Deploy profile artifacts to app config paths ──────────
              deploy_artifacts() {
                local src="$1"
                local dst="$2"
                if [ ! -f "$src" ]; then
                  warn "deploy: artifact missing: $src"
                  return 0
                fi
                local dst_dir
                dst_dir=$(dirname "$dst")
                if [ ! -d "$dst_dir" ]; then
                  warn "deploy: target dir missing: $dst_dir"
                  return 0
                fi
                if cp "$src" "$dst" 2>/dev/null; then
                  log "deploy: $(basename "$src") → $dst"
                  return 0
                else
                  warn "deploy: copy failed (read-only?): $dst"
                  return 0
                fi
              }

              # Deploy each artifact to its app config path
              deploy_artifacts "$profile_dir/hypr/wallust-hyprland.conf" "$HOME/.config/hypr/wallust/wallust-hyprland.conf"
              deploy_artifacts "$profile_dir/waybar/colors-waybar.css" "$HOME/.config/waybar/wallust/colors-waybar.css"
              deploy_artifacts "$profile_dir/rofi/colors-rofi.rasi" "$HOME/.config/rofi/wallust/colors-rofi.rasi"
              deploy_artifacts "$profile_dir/gtk/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
              # Starship prompt colors. NixOS's programs.starship defers to
              # ~/.config/starship.toml when it exists, so swapping it here makes
              # the prompt follow the active theme (light's blue is unreadable
              # against the dark-preset prompt colors otherwise).
              deploy_artifacts "$profile_dir/terminals/starship.toml" "$HOME/.config/starship.toml"
              # tmux statusline/colors — full generated config, safe to
              # overwrite wholesale; reloaded live in the hooks below. Without
              # this the statusbar stays on the dark preset (light-blue text).
              deploy_artifacts "$profile_dir/terminals/tmux.conf" "$HOME/.config/tmux/tmux.conf"
              # alacritty + k9s were also frozen on the active (dark) preset —
              # their configs carry the full color set, safe to overwrite. k9s
              # picks up the skin on next launch; alacritty live-reloads.
              deploy_artifacts "$profile_dir/terminals/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
              deploy_artifacts "$profile_dir/terminals/k9s/tokyonight.yaml" "$HOME/.config/k9s/skins/tokyonight.yaml"
              # Deploy kitty terminal colors (preserve operational lines from current config)
              kitty_src="$profile_dir/terminals/kitty.conf"
              kitty_dst="$HOME/.config/kitty/kitty.conf"
              if [[ -f "$kitty_src" ]]; then
                mkdir -p "$(dirname "$kitty_dst")"
                kitty_tmp=$(mktemp)
                if [[ -f "$kitty_dst" ]]; then
                  cp "$kitty_dst" "$kitty_tmp"
                fi
                if cp "$kitty_src" "$kitty_dst" 2>/dev/null; then
                  log "deploy: kitty.conf → $kitty_dst"
                else
                  warn "deploy: kitty.conf copy failed"
                fi
                # Restore operational lines from original config (set by nix, not in profile)
                if [[ -f "$kitty_tmp" ]]; then
                  grep -E '^(shell|allow_remote_control|listen_on) ' "$kitty_tmp" >> "$kitty_dst" || true
                fi
                rm -f "$kitty_tmp"
              fi

              # Hyprland
              if command -v hyprctl >/dev/null 2>&1; then
                hyprctl reload >/dev/null 2>&1 && log "hyprctl reload: ok" || warn "hyprctl reload failed"
              else
                warn "hook: hyprctl not available"
              fi

              # Waybar — click handlers can run with a restricted PATH, so use
              # procps from the Nix store instead of relying on pgrep/pkill on PATH.
              if ${pkgs.procps}/bin/pkill -SIGUSR2 -x waybar >/dev/null 2>&1 \
                || ${pkgs.procps}/bin/pkill -SIGUSR2 -f '(^|[[:space:]/])waybar([[:space:]]|$)' >/dev/null 2>&1; then
                log "waybar reload: ok"
              else
                warn "hook: waybar not running"
              fi

              # tmux — reload config live for the running server (best-effort)
              if ${pkgs.tmux}/bin/tmux list-sessions >/dev/null 2>&1; then
                ${pkgs.tmux}/bin/tmux source-file "$HOME/.config/tmux/tmux.conf" >/dev/null 2>&1 \
                  && log "tmux source-file: ok" || warn "tmux source-file failed"
              else
                warn "hook: tmux server not running"
              fi

              # Kitty remote — live retheme via kitty remote control socket
              if command -v kitty >/dev/null 2>&1; then
                local kitty_conf="$profile_dir/terminals/kitty.conf"
                kitty_socket=$(find "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}" -maxdepth 1 -name 'jvf-kitty-remote*' -type s 2>/dev/null | head -1)
                if [ -n "$kitty_socket" ]; then
                  if [ -f "$kitty_conf" ]; then
                    kitty @ --to "unix:$kitty_socket" set-colors --all "$kitty_conf" 2>/dev/null \
                      && log "kitty set-colors: ok" || warn "kitty set-colors failed"
                    kitty @ --to "unix:$kitty_socket" load-config 2>/dev/null \
                      && log "kitty load-config: ok" || warn "kitty load-config failed (kitty may need restart)"
                  else
                    warn "hook: kitty.conf not found in profile"
                  fi
                else
                  warn "hook: kitty remote socket not available ($kitty_socket)"
                fi
              else
                warn "hook: kitty not available"
              fi

              # Desktop color-scheme for portal-aware apps (Brave/Chromium, GTK).
              # Write via dconf, not gsettings: the org.gnome.desktop.interface
              # schema is not installed in this environment, so `gsettings set`
              # always fails. dconf writes the same key directly, and
              # xdg-desktop-portal-gtk relays it as org.freedesktop.appearance
              # color-scheme — which Chromium honors live. Keyed off the profile
              # (not $mode) so `auto` resolves correctly too.
              local color_scheme
              case "$(basename "$profile_dir")" in
                light) color_scheme="prefer-light" ;;
                *)     color_scheme="prefer-dark" ;;
              esac
              if dconf write /org/gnome/desktop/interface/color-scheme "'$color_scheme'" 2>/dev/null; then
                log "dconf color-scheme: $color_scheme"
              else
                warn "dconf color-scheme write failed"
              fi

              # Btop — repoint the stable jvf-active.theme symlink so btop
              # loads the current profile's theme. btop.conf keeps a fixed
              # color_theme = "jvf-active": btop rewrites btop.conf on exit,
              # so editing color_theme there at runtime gets clobbered.
              if [ -d "$profile_dir/btop" ]; then
                local btop_theme
                btop_theme=$(find "$profile_dir/btop" -name '*.theme' -type f 2>/dev/null | head -1)
                if [ -n "$btop_theme" ]; then
                  local btop_themes_dir="$HOME/.config/btop/themes"
                  mkdir -p "$btop_themes_dir"
                  ln -sf "$btop_theme" "$btop_themes_dir/jvf-active.theme" 2>/dev/null \
                    && log "btop theme symlink: ok" || warn "btop theme symlink failed"
                fi
              fi
              # Export JVF_THEME env var for other apps (neovim, etc)
              mkdir -p "$STATE_DIR"
              echo "export JVF_THEME='$profile'" > "$STATE_DIR/env"
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

            do_toggle() {
              local target
              target=$(readlink "$STATE_DIR/current" 2>/dev/null || echo "")
              if [ "$(basename "$target" 2>/dev/null || echo "")" = "light" ]; then
                do_switch dark dark
              else
                do_switch light light
              fi
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
              toggle) do_toggle ;;
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
