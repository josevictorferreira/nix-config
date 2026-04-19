#!/usr/bin/env bash

TODO_FILE="$HOME/Homelab/notetaking/01-projects/active/Todo.md"

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    exit 0
fi

# Exit if file doesn't exist
if [ ! -f "$TODO_FILE" ]; then
    notify-send "Todo" "No todo file found"
    exit 1
fi

# Extract unchecked items with their line numbers
mapfile -t items < <(grep -n "^- \[ \]" "$TODO_FILE")

# Exit if no unchecked items
if [ ${#items[@]} -eq 0 ]; then
    notify-send "Todo" "No unchecked items found"
    exit 0
fi

# Build display list (strip line number prefix for rofi display)
display_items=()
for item in "${items[@]}"; do
    display_items+=("$(echo "$item" | cut -d: -f2- | sed 's/^- \[ \] //')")
done

# Show rofi menu with unchecked items
selected=$(printf '%s\n' "${display_items[@]}" | rofi -dmenu -p "Complete task:" -theme-str 'entry { placeholder: "Select task to complete..."; }')

# Exit if user cancelled
if [ -z "$selected" ]; then
    exit 0
fi

# Find the line number of the selected item
timestamp=$(date +" ✅ %Y-%m-%d %H:%M")
tmp=$(mktemp)

while IFS= read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    content=$(echo "$line" | cut -d: -f2- | sed 's/^- \[ \] //')
    if [ "$content" = "$selected" ]; then
        sed "${line_num}s/- \[ \]/- [x]/;${line_num}s/$/${timestamp}/" "$TODO_FILE" > "$tmp" && mv "$tmp" "$TODO_FILE"
        notify-send "Todo" "Completed: $selected"
        exit 0
    fi
done < <(grep -n "^- \[ \]" "$TODO_FILE")
