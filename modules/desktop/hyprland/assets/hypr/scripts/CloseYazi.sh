#!/usr/bin/env bash
# Close Yazi scratchpad only when it's focused
# Returns control to normal ESC behavior if yazi is not focused

YAZI_CLASS="yazi-fm"

# Get the class of the active window
ACTIVE_CLASS=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class' 2>/dev/null)

# Only close if yazi-fm is the active window
if [ "$ACTIVE_CLASS" = "$YAZI_CLASS" ]; then
    # Toggle the special workspace to close it
    hyprctl dispatch togglespecialworkspace yazi
fi