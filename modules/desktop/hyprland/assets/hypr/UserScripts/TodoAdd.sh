#!/usr/bin/env bash

TODO_FILE="$HOME/Homelab/notetaking/01-projects/active/Todo.md"

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    exit 0
fi

# Prompt for todo text via rofi
text=$(rofi -dmenu -p "New todo:" -theme-str 'entry { placeholder: "Add a new task..."; }')

# Exit if user cancelled or empty input
if [ -z "$text" ]; then
    exit 0
fi

# Create directory if it doesn't exist
mkdir -p "$(dirname "$TODO_FILE")"

# Create file if it doesn't exist
touch "$TODO_FILE"

# Ensure file has at least 3 lines so insertion lands at line 4
line_count=$(wc -l < "$TODO_FILE")
while [ "$line_count" -lt 3 ]; do
    echo "" >> "$TODO_FILE"
    line_count=$((line_count + 1))
done

# Insert todo item at line 4
tmp=$(mktemp)
sed "4i - [ ] ${text}" "$TODO_FILE" > "$tmp" && mv "$tmp" "$TODO_FILE"
