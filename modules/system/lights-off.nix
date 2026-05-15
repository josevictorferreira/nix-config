# Aspect: system-lights-off
# Custom command to turn off all hardware lights.
# NixOS-only (no Darwin equivalent).
_:
let
  lightsOffModule =
    { lib, pkgs, ... }:
    let
      lights-off = pkgs.writeShellScriptBin "lights-off" ''
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl dispatch dpms off
        fi

        if command -v openrgb >/dev/null 2>&1; then
            sudo openrgb --mode static --color 000000 > /dev/null 2>&1
        fi

        if command -v liquidctl >/dev/null 2>&1; then
            sudo liquidctl initialize all > /dev/null 2>&1
            sudo liquidctl set sync color off > /dev/null 2>&1
            for channel in logo ring fan external; do
                sudo liquidctl set "$channel" color off > /dev/null 2>&1
            done
            sudo liquidctl set lcd screen brightness 0 > /dev/null 2>&1
            sudo liquidctl set lcd screen static black > /dev/null 2>&1
        fi
      '';
    in
    {
      config = {
        environment.systemPackages = [
          lights-off
          pkgs.liquidctl
        ];
      };
    };
in
{
  flake.modules.nixos.system-lights-off = lightsOffModule;
}
