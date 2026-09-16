# Aspect: hardware-moonlander
# ZSA Moonlander keyboard support: host-side LED control via keymapp + kontroll.
#
# The Moonlander runs its own firmware and owns its LEDs -- OpenRGB cannot reach
# a stock Oryx-firmware board (it doesn't speak OpenRGB's QMK protocol). The only
# host-side channel is ZSA's keymapp API: keymapp holds the USB connection and
# exposes a per-user Unix socket (~/.config/.keymapp/keymapp.sock); `kontroll`
# drives it from scripts. `lights-off` calls kontroll to blank the LEDs.
#
# `moonlander-leds` undoes that blanking at the start of every Hyprland session,
# so `lights-off` stops being a one-way door. It must set an EXPLICIT colour:
# `kontroll restore-rgb-leds` hands control back to the firmware, whose default
# on this board is dark (the flashed Oryx layout `nvim,i3,tmux` contains no RGB
# keycode at all, so its layer colours stay gated off and nothing on the board
# can re-enable them). Until the layout is reflashed with `RGB_TOG` /
# `TOGGLE_LAYER_COLOR`, the host is the only thing that can light this keyboard.
# NixOS-only (no Darwin equivalent).
_:
let
  mkConfig =
    { pkgs, ... }:
    let
      kontroll = "${pkgs.kontroll}/bin/kontroll";

      # Default colour: tokyonight blue, matching jvf.theme colour4.
      moonlander-leds = pkgs.writeShellScriptBin "moonlander-leds" ''
        color="''${1:-7aa2f7}"

        # keymapp is launched next to this at session start and takes a moment
        # to create its API socket; without it kontroll has no channel at all.
        sock="$HOME/.config/.keymapp/keymapp.sock"
        for _ in $(seq 30); do
            [ -S "$sock" ] && break
            sleep 1
        done
        [ -S "$sock" ] || exit 0

        # The socket is created before keymapp has finished negotiating with
        # the board, so a single shot here loses a race it cannot see: for up to
        # ~20s set-rgb-all fails with "no keyboard is connected" or the
        # misleading "keyboard requires an updated firmware" (which does NOT
        # mean the firmware is old -- keymapp just has not read its version
        # yet). Retry until the paint takes, re-running connect-any each round
        # in case keymapp's own autoconnect has not landed either. connect-any
        # exits non-zero with "keyboard already connected" once it has, which is
        # fine.
        for _ in $(seq 60); do
            ${kontroll} connect-any > /dev/null 2>&1 || true
            ${kontroll} set-rgb-all --color "$color" --sustain 0 > /dev/null 2>&1 && exit 0
            sleep 1
        done
      '';
    in
    {
      config = {
        environment.systemPackages = [
          pkgs.keymapp # GUI daemon that owns the keyboard connection + API
          pkgs.kontroll # CLI client for the keymapp API (used by lights-off)
          moonlander-leds # repaints the LEDs at session start
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
