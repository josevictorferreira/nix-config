# Aspect: hardware-airpods
# LibrePods: AirPods battery, listening-mode control, and ear detection on Linux.
# NixOS-only. Requires Apple VendorID spoofing (see hardware-bluetooth DeviceID).
_:
let
  mkAirpodsOptions =
    { config, lib, ... }:
    {
      options.jvf.hardware.airpods = {
        username = lib.mkOption {
          type = lib.types.str;
          default = config.jvf.core.username;
          description = "Primary user to add to the librepods group.";
        };
      };
    };

  mkConfig =
    { config, pkgs, ... }:
    let
      cfg = config.jvf.hardware.airpods;

      # Waybar glue for LibrePods. `librepods-ctl` is write-only (noise:* only),
      # and LibrePods exposes no D-Bus control interface — its tray item is the
      # only readable surface, so battery comes from the StatusNotifierItem
      # tooltip and "open the window" is the tray item's own Activate() method.
      airpodsCore = pkgs.writeShellScriptBin "airpods-core" ''
        set -u
        export PATH=${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.bluez}/bin:${pkgs.systemd}/bin:${pkgs.util-linux}/bin:${pkgs.procps}/bin:$PATH

        ICON="󱡏"  # nf-md-earbuds (U+F184F)

        # Echoes "<bus-name> <object-path>" of LibrePods' tray item, else fails.
        sni_item() {
          local items entry svc path
          items=$(busctl --user get-property org.kde.StatusNotifierWatcher \
                    /StatusNotifierWatcher org.kde.StatusNotifierWatcher \
                    RegisteredStatusNotifierItems 2>/dev/null) || return 1
          for entry in $(tr ' ' '\n' <<<"$items" | tr -d '"' | grep '^:'); do
            svc=''${entry%%/*}
            path=/''${entry#*/}
            if [ "$(busctl --user get-property "$svc" "$path" \
                      org.kde.StatusNotifierItem Id 2>/dev/null)" = 's "librepods"' ]; then
              printf '%s %s\n' "$svc" "$path"
              return 0
            fi
          done
          return 1
        }

        # True when a connected Bluetooth device reports Apple's vendor id (0x004C).
        airpods_connected() {
          local mac
          while read -r _ mac _; do
            [ -n "$mac" ] || continue
            bluetoothctl info "$mac" 2>/dev/null | grep -qi 'Modalias:.*v004C' && return 0
          done < <(bluetoothctl devices Connected 2>/dev/null)
          return 1
        }

        cmd_status() {
          airpods_connected || { echo '{}'; return; }

          local item tip left right
          if ! item=$(sni_item); then
            printf '{"text": "%s", "tooltip": "AirPods connected — LibrePods not running", "class": "no-daemon"}\n' \
              "$ICON"
            return
          fi

          # ToolTip: (sa(iiay)ss) "" 0 "Battery Status: Left: 68%, Right: 73%, Case: 0%" ""
          tip=$(busctl --user get-property $item org.kde.StatusNotifierItem ToolTip 2>/dev/null)
          left=$(sed -n 's/.*Left: \([0-9]\+\)%.*/\1/p' <<<"$tip")
          right=$(sed -n 's/.*Right: \([0-9]\+\)%.*/\1/p' <<<"$tip")

          if [ -n "$left" ] && [ -n "$right" ]; then
            printf '{"text": "%s %s/%s%%", "tooltip": "AirPods — L %s%%  R %s%%", "class": "connected"}\n' \
              "$ICON" "$left" "$right" "$left" "$right"
          else
            # Daemon alive but its AAP link dropped: the tooltip empties and
            # Activate() stops opening a window. Only a restart recovers it.
            printf '{"text": "%s !", "tooltip": "LibrePods lost the AirPods link — click to restart", "class": "stale"}\n' \
              "$ICON"
          fi
        }

        # Closing the LibrePods window leaves the process alive with no window,
        # so hl.dsp.focus cannot bring it back — Activate() is what a tray click
        # sends, and that is what re-creates the window.
        activate() {
          local item
          item=$(sni_item) || return 1
          busctl --user call $item org.kde.StatusNotifierItem Activate ii 0 0
        }

        cmd_open() {
          local item tip i
          if item=$(sni_item); then
            tip=$(busctl --user get-property $item org.kde.StatusNotifierItem ToolTip 2>/dev/null)
            if grep -q 'Left: [0-9]' <<<"$tip"; then
              activate
              return
            fi
            # Blind daemon: Activate() is a no-op, so replace it.
            pkill -f 'bin/librepods( |$)' 2>/dev/null
            sleep 2
          fi

          setsid -f /run/wrappers/bin/librepods --hide >/dev/null 2>&1
          # Wait for the fresh instance to claim its tray item, then show it.
          for i in $(seq 1 30); do
            activate >/dev/null 2>&1 && return
            sleep 0.3
          done
        }

        case "''${1:-status}" in
          open) cmd_open ;;
          *)    cmd_status ;;
        esac
      '';
    in
    {
      imports = [ mkAirpodsOptions ];

      config = {
        # Installs librepods plus a cap_net_admin wrapper gated on the
        # librepods group; the raw L2CAP socket to the AirPods needs it.
        programs.librepods.enable = true;

        users.users.${cfg.username}.extraGroups = [ "librepods" ];

        # Commands the Waybar `custom/airpods` module calls.
        jvf.wrappers.users.${cfg.username}.programs = {
          "airpods-waybar-status".command = "${airpodsCore}/bin/airpods-core status";
          "airpods-open".command = "${airpodsCore}/bin/airpods-core open";
        };
      };
    };
in
{
  flake.modules.nixos.hardware-airpods = mkConfig;
}
