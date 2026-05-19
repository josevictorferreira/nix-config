#!/usr/bin/env bash
# Close scratchpad (yazi/todo) only when focused
# Returns control to normal ESC behavior if no scratchpad is focused

# Check active window class
ACTIVE_CLASS=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class' 2>/dev/null)

# Close yazi if focused
if [ "$ACTIVE_CLASS" = "yazi-fm" ]; then
    hyprctl dispatch togglespecialworkspace yazi
fi

# Close todo if focused
if [ "$ACTIVE_CLASS" = "todo-nvim" ]; then
    hyprctl dispatch togglespecialworkspace todo
fi