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

      # Cuts / restores bus power on every root-hub USB port that is not
      # carrying an input device.
      #
      # IMPORTANT, measured on this box: clearing a port does NOT necessarily
      # drop VBUS. usb3-port1 (the external 214b:7250 rack) goes to
      # state=not attached and leaves sysfs entirely, yet its LEDs stay lit --
      # the board has no load-switch IC gating 5V on that port, so the xHCI
      # PORTSC PP bit toggles with nothing downstream listening. uhubctl agrees
      # and refuses every hub here ("No compatible devices detected"). Ports on
      # the other controller (0000:02:00.0) are untested.
      #
      # Root is required, and the uaccess trick used for OpenRGB and the
      # Moonlander does not apply: usb_port devices have an empty SUBSYSTEM and
      # emit no udev events, so no rule can match them. Hence the narrow
      # NOPASSWD sudo rule below, which keeps `lights-off` non-interactive.
      #
      # Deliberately uses only bash builtins: it runs under sudo's secure_path,
      # where coreutils are not guaranteed to be on PATH.
      stateFile = "/run/lights-off-usb-ports";

      usb-power = pkgs.writeShellScript "usb-power" ''
        set -eu
        case "''${1-}" in
          off)
            : > ${stateFile}
            for hub in /sys/bus/usb/devices/usb*; do
              bus=''${hub##*/usb}
              for p in "$hub/$bus-0:1.0/usb$bus-port"*; do
                [ -d "$p" ] || continue
                [ -e "$p/device" ] || continue
                dev=$p/device
                # Leave HID ports powered. Cutting the keyboard or mouse would
                # leave no way to wake the blanked displays or run `lights-on`.
                # The globs cover a device's own interfaces (`3-4:1.0`) plus
                # those of anything behind a hub on that port (`3-1/3-1.1/...`).
                # Descend only into USB-device-shaped names: a bare `*` would
                # follow the `subsystem` symlink out to /sys/bus/usb and match
                # every interface on the machine, marking every port HID.
                hid=0
                for ifc in "$dev"/*:*/bInterfaceClass \
                           "$dev"/[0-9]*-*/*:*/bInterfaceClass \
                           "$dev"/[0-9]*-*/[0-9]*-*/*:*/bInterfaceClass; do
                  [ -f "$ifc" ] || continue
                  read -r cls < "$ifc" || continue
                  [ "$cls" = "03" ] && hid=1
                done
                [ "$hid" = "0" ] || continue
                attr=$p/disable
                [ -w "$attr" ] || continue
                # Record before cutting: a powered-down device leaves sysfs.
                printf '%s\n' "$attr" >> ${stateFile}
                echo 1 > "$attr"
              done
            done
            ;;
          on)
            [ -s ${stateFile} ] || exit 0
            while read -r attr; do
              [ -n "$attr" ] || continue
              [ -w "$attr" ] && echo 0 > "$attr"
            done < ${stateFile}
            : > ${stateFile}
            ;;
          *)
            echo "usage: usb-power on|off" >&2
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

        # USB: cut bus power to every port not carrying an input device (the
        # rack, the audio interface, the webcam). Unlike every other step this
        # latches -- those devices stay down until `lights-on`. stderr is left
        # visible so a failed sudo rule is not silently swallowed.
        ${sudo} -n ${usb-power} off || true

        # Displays: blank the monitors via Hyprland DPMS. They wake on any
        # keyboard/mouse input. Runs last so the RGB commands complete first.
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl dispatch 'hl.dsp.dpms("off")' > /dev/null 2>&1
        fi
      '';

      lights-on = pkgs.writeShellScriptBin "lights-on" ''
        # Restores the only thing `lights-off` latches: bus power to the USB
        # ports it cut. The displays wake on input and the RGB devices reset on
        # the next profile change, so nothing else to undo.
        ${sudo} -n ${usb-power} on || true
      '';
    in
    {
      config = {
        environment.systemPackages = [
          lights-off
          lights-on
        ];

        # Let the desktop user cut USB port power without a password prompt,
        # scoped to this one helper -- `lights-off` must stay non-interactive.
        security.sudo.extraRules = [
          {
            groups = [ "wheel" ];
            commands = [
              {
                command = "${usb-power}";
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
