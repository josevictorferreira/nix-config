# Aspect: system-lights-off
# Custom command to turn off all hardware lights.
# NixOS-only (no Darwin equivalent).
_:
let
  lightsOffModule =
    { pkgs, config, ... }:
    let
      # Absolute store path so the passwordless-sudo rule below matches exactly
      # (a bare `liquidctl` resolves via a /run symlink and would not match).
      liquidctl = "${pkgs.liquidctl}/bin/liquidctl";

      lights-off = pkgs.writeShellScriptBin "lights-off" ''
        # RGB (RAM, motherboard, Kraken ring): apply the committed all-dark
        # profile. Runs as the user -- OpenRGB's systemd server grants i2c/HID
        # access via udev uaccess, so no sudo is needed and the profile resolves
        # from ~/.config/OpenRGB (deployed by jvf.home below).
        if command -v openrgb >/dev/null 2>&1; then
            openrgb --profile lights-off > /dev/null 2>&1
        fi

        # Kraken LCD screen: not an RGB zone, so OpenRGB can't reach it.
        # Passwordless sudo (security.sudo.extraRules below) keeps this a single
        # non-interactive command.
        if [ -x ${liquidctl} ]; then
            sudo ${liquidctl} initialize all > /dev/null 2>&1
            sudo ${liquidctl} set lcd screen brightness 0 > /dev/null 2>&1
            sudo ${liquidctl} set lcd screen static black > /dev/null 2>&1
        fi
      '';
    in
    {
      config = {
        environment.systemPackages = [
          lights-off
          pkgs.liquidctl
        ];

        # Deploy the all-dark OpenRGB profile so `lights-off` can apply it by
        # name via `openrgb --profile lights-off`.
        jvf.home.xdg.config."OpenRGB/lights-off.orp" = {
          kind = "file";
          mode = "copy";
          source = ./lights-off.orp;
        };

        # Let `lights-off` blank the Kraken LCD without a password prompt, so it
        # stays a single non-interactive command.
        security.sudo.extraRules = [
          {
            users = [ config.jvf.core.username ];
            commands = [
              {
                command = liquidctl;
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];
      };
    };
in
{
  flake.modules.nixos.system-lights-off = lightsOffModule;
}
