#!/usr/bin/env bash
# Toggle Yazi scratchpad with crash recovery
# If yazi-fm is not running, start it before toggling the special workspace

YAZI_CLASS="yazi-fm"
YAZI_CMD="kitty --class=yazi-fm -e yazi"

# Check if yazi-fm window exists
if ! hyprctl clients -j | jq -e '.[] | select(.class == "'"$YAZI_CLASS"'")' > /dev/null 2>&1; then
    # Not running — start it in the background
    $YAZI_CMD &
    # Give it a moment to spawn
    sleep 0.3
fi

# Toggle the special workspace
hyprctl dispatch togglespecialworkspace yazi

# Focus the window after toggling
sleep 0.05
hyprctl dispatch focuswindow "class:^($YAZI_CLASS)$"
