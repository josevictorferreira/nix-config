# Aspect: system-lights-off
# Custom command to turn off all hardware lights + blank the displays.
# `lights-on` undoes the one step that does not restore itself.
# NixOS-only (no Darwin equivalent).
_:
let
  lightsOffModule =
    { pkgs, ... }:
    let
      kontroll = "${pkgs.kontroll}/bin/kontroll";
      sudo = "/run/wrappers/bin/sudo";

      # The external USB rack is a bus-powered 214b:7250 hub (a 4-port hub with
      # a second one chained behind it). Being bus-powered, its own indicator
      # LEDs -- and everything plugged into it -- go dark only when the
      # motherboard port feeding it drops power.
      #
      # uhubctl cannot do this: no hub on this machine advertises per-port power
      # switching, so it reports "No compatible devices detected". The kernel's
      # usb_port `disable` attribute is more permissive (it also covers ganged
      # and root hubs) and clears the xHCI PORTSC power bit directly.
      #
      # Root is required, and the uaccess trick used for OpenRGB and the
      # Moonlander does not apply: usb_port devices have an empty SUBSYSTEM and
      # emit no udev events, so no rule can match them. Hence the narrow
      # NOPASSWD sudo rule below, which keeps `lights-off` non-interactive.
      rackVendor = "214b";
      rackProduct = "7250";
      stateFile = "/run/lights-off-usb-rack-port";

      usb-rack-power = pkgs.writeShellScript "usb-rack-power" ''
        set -eu
        case "''${1-}" in
          off)
            for d in /sys/bus/usb/devices/*; do
              [ "$(cat "$d/idVendor" 2>/dev/null)" = "${rackVendor}" ] || continue
              [ "$(cat "$d/idProduct" 2>/dev/null)" = "${rackProduct}" ] || continue
              n=''${d##*/}
              # Skip the hub chained inside the rack: same chip ID, but it is
              # not the one drawing power from the motherboard. A dot in the
              # sysfs name means "behind a hub" (3-1.4) rather than a root
              # port (3-1).
              case "$n" in *.*) continue ;; esac
              bus=''${n%%-*}
              port=''${n#*-}
              attr=/sys/bus/usb/devices/usb$bus/$bus-0:1.0/usb$bus-port$port/disable
              [ -w "$attr" ] || continue
              # Record the port before cutting it: once power drops, the rack
              # leaves sysfs and can no longer be found by vendor/product.
              printf '%s\n' "$attr" > ${stateFile}
              echo 1 > "$attr"
            done
            ;;
          on)
            [ -f ${stateFile} ] || exit 0
            attr=$(cat ${stateFile})
            [ -w "$attr" ] && echo 0 > "$attr"
            rm -f ${stateFile}
            ;;
          *)
            echo "usage: usb-rack-power on|off" >&2
            exit 2
            ;;
        esac
      '';

      lights-off = pkgs.writeShellScriptBin "lights-off" ''
        # RGB (RAM, motherboard, Kraken ring): apply the committed all-dark
        # profile. Runs as the user -- OpenRGB's systemd server grants i2c/HID
        # access via udev uaccess, so no sudo is needed and the profile resolves
        # from ~/.config/OpenRGB (deployed by jvf.home below).
        if command -v openrgb >/dev/null 2>&1; then
            openrgb --profile lights-off > /dev/null 2>&1
        fi

        # Moonlander keyboard: OpenRGB can't reach it, so drive its LEDs through
        # keymapp's API via kontroll. keymapp must be running with its API
        # enabled (autostarted in the Hyprland session). connect-any is
        # idempotent; --sustain 0 holds black until the next change.
        if [ -x ${kontroll} ]; then
            ${kontroll} connect-any > /dev/null 2>&1
            ${kontroll} set-rgb-all --color 000000 --sustain 0 > /dev/null 2>&1
        fi

        # USB rack: cut bus power to the hub, killing its own LEDs along with
        # the Bluetooth dongle inside it. Unlike every other step this latches
        # -- Bluetooth stays down until `lights-on`. stderr is left visible so a
        # failed sudo rule or a moved rack is not silently swallowed.
        ${sudo} -n ${usb-rack-power} off || true

        # Displays: blank the monitors via Hyprland DPMS. They wake on any
        # keyboard/mouse input. Runs last so the RGB commands complete first.
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl dispatch 'hl.dsp.dpms("off")' > /dev/null 2>&1
        fi
      '';

      lights-on = pkgs.writeShellScriptBin "lights-on" ''
        # Restores the only thing `lights-off` latches: bus power to the USB
        # rack (and with it Bluetooth). The displays wake on input and the RGB
        # devices reset on the next profile change, so nothing else to undo.
        ${sudo} -n ${usb-rack-power} on || true
      '';
    in
    {
      config = {
        environment.systemPackages = [
          lights-off
          lights-on
        ];

        # Let the desktop user cut USB rack power without a password prompt,
        # scoped to this one helper -- `lights-off` must stay non-interactive.
        security.sudo.extraRules = [
          {
            groups = [ "wheel" ];
            commands = [
              {
                command = "${usb-rack-power}";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];

        # Deploy the all-dark OpenRGB profile so `lights-off` can apply it by
        # name via `openrgb --profile lights-off`.
        jvf.home.xdg.config."OpenRGB/lights-off.orp" = {
          kind = "file";
          mode = "copy";
          source = ./lights-off.orp;
        };
      };
    };
in
{
  flake.modules.nixos.system-lights-off = lightsOffModule;
}
