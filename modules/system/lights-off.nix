# Aspect: system-lights-off
# Custom command to turn off all hardware lights + blank the displays.
# NixOS-only (no Darwin equivalent).
_:
let
  lightsOffModule =
    { pkgs, ... }:
    let
      kontroll = "${pkgs.kontroll}/bin/kontroll";

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

        # Displays: blank the monitors via Hyprland DPMS. They wake on any
        # keyboard/mouse input. Runs last so the RGB commands complete first.
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl dispatch dpms off > /dev/null 2>&1
        fi
      '';
    in
    {
      config = {
        environment.systemPackages = [
          lights-off
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
