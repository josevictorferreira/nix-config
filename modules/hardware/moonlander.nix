# Aspect: hardware-moonlander
# ZSA Moonlander keyboard support: host-side LED control via keymapp + kontroll.
#
# The Moonlander runs its own firmware and owns its LEDs -- OpenRGB cannot reach
# a stock Oryx-firmware board (it doesn't speak OpenRGB's QMK protocol). The only
# host-side channel is ZSA's keymapp API: keymapp holds the USB connection and
# exposes a per-user Unix socket (~/.config/.keymapp/keymapp.sock); `kontroll`
# drives it from scripts. `lights-off` calls kontroll to blank the LEDs.
# NixOS-only (no Darwin equivalent).
_:
let
  mkConfig =
    { pkgs, ... }:
    {
      config = {
        environment.systemPackages = [
          pkgs.keymapp # GUI daemon that owns the keyboard connection + API
          pkgs.kontroll # CLI client for the keymapp API (used by lights-off)
        ];

        # Grant the logged-in user uaccess to the Moonlander's hidraw nodes
        # (vendor 3297). Without this the nodes are root-only and keymapp,
        # running as the user, cannot open the keyboard.
        services.udev.packages = [ pkgs.zsa-udev-rules ];
      };
    };
in
{
  flake.modules.nixos.hardware-moonlander = mkConfig;
}
