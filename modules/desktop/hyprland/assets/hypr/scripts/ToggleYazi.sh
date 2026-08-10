#!/usr/bin/env bash
# Toggle Yazi scratchpad with crash recovery
# If yazi-fm is not running, start it before toggling the special workspace

YAZI_CLASS="yazi-fm"
YAZI_CMD="kitty --class=yazi-fm -e yazi"

yazi_running() {
    hyprctl clients -j | jq -e '.[] | select(.class == "'"$YAZI_CLASS"'")' > /dev/null 2>&1
}

# Check if yazi-fm window exists
if ! yazi_running; then
    # Not running — start it in the background
    $YAZI_CMD &
    # Wait for the window to register with Hyprland (up to 3 seconds)
    for i in $(seq 1 30); do
        if yazi_running; then break; fi
        sleep 0.1
    done
fi

# Toggle the special workspace
hyprctl dispatch 'hl.dsp.workspace.toggle_special("yazi")'

# Focus the window after toggling
sleep 0.05
hyprctl dispatch "hl.dsp.focus({window = 'class:^($YAZI_CLASS)\$'})"
