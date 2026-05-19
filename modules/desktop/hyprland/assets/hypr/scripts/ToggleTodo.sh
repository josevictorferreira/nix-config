#!/usr/bin/env bash
# Toggle Todo.md scratchpad with crash recovery
# Opens neovim editing ~/Homelab/notetaking/projects/active/Todo.md

TODO_CLASS="todo-nvim"
TODO_FILE="$HOME/Homelab/notetaking/01-projects/active/Todo.md"

todo_running() {
    hyprctl clients -j | jq -e '.[] | select(.class == "'"$TODO_CLASS"'")' > /dev/null 2>&1
}

# Ensure Todo.md file exists
if [ ! -f "$TODO_FILE" ]; then
    mkdir -p "$(dirname "$TODO_FILE")"
    touch "$TODO_FILE"
fi

# Check if todo-nvim window exists
if ! todo_running; then
    # Not running — start it in the background
    $TODO_CMD &
    # Wait for the window to register with Hyprland (up to 3 seconds)
    for i in $(seq 1 30); do
        if todo_running; then break; fi
        sleep 0.1
    done
fi

# Toggle the special workspace
hyprctl dispatch togglespecialworkspace todo

# Focus the window after toggling
sleep 0.05
hyprctl dispatch focuswindow "class:^($TODO_CLASS)$"