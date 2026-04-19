#!/usr/bin/env bash

TODO_FILE="$HOME/Homelab/notetaking/01-projects/activbe/Todo.md"

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    exit 0
fi

# Prompt for todo text via rofi
text=$(rofi -dmenu -p "New todo:" -config "$HOME/.config/rofi/config-compact.rasi")

# Exit if user cancelled or empty input
if [ -z "$text" ]; then
    exit 0
fi

# Create directory if it doesn't exist
mkdir -p "$(dirname "$TODO_FILE")"

# Create file if it doesn't exist
touch "$TODO_FILE"

# Ensure file has at least 2 lines so insertion lands at line 3
line_count=$(wc -l < "$TODO_FILE")
while [ "$line_count" -lt 2 ]; do
    echo "" >> "$TODO_FILE"
    line_count=$((line_count + 1))
done

# Insert todo item at line 3
sed -i "3i - [ ] ${text}" "$TODO_FILE"
