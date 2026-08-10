#!/usr/bin/env bash

notif="$HOME/.config/swaync/images/bell.png"

export STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"

# The hyprlang `$TOUCHPAD_ENABLED` variable does not exist under the Lua config
# (and `hyprctl keyword` no longer works either), so toggle the device directly.
# Keep this name in sync with Touchpad_Device in UserConfigs/laptop.lua.
TOUCHPAD_DEVICE="asue1209:00-04f3:319f-touchpad"

set_touchpad() {
    hyprctl eval "hl.device({ name = \"$TOUCHPAD_DEVICE\", enabled = $1 })"
}

enable_touchpad() {
    printf "true" >"$STATUS_FILE"
    notify-send -u low -i $notif  "Enabling touchpad"
    set_touchpad true
}

disable_touchpad() {
    printf "false" >"$STATUS_FILE"
    notify-send -u low -i $notif "Disabling touchpad"
    set_touchpad false
}

if ! [ -f "$STATUS_FILE" ]; then
  enable_touchpad
else
  if [ $(cat "$STATUS_FILE") = "true" ]; then
    disable_touchpad
  elif [ $(cat "$STATUS_FILE") = "false" ]; then
    enable_touchpad
  fi
fi
