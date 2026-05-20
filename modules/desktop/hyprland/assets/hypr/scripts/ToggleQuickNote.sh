#!/usr/bin/env bash
# Toggle Quick Notes.md scratchpad with crash recovery
# Opens neovim editing ~/Homelab/notetaking/01-projects/active/Quick Notes.md

QUICK_NOTE_CLASS="quick-note-nvim"
QUICK_NOTE_FILE="$HOME/Homelab/notetaking/01-projects/active/Quick Notes.md"

quick_note_running() {
    hyprctl clients -j | jq -e '.[] | select(.class == "'"$QUICK_NOTE_CLASS"'")' > /dev/null 2>&1
}

# Ensure Quick Notes.md file exists
if [ ! -f "$QUICK_NOTE_FILE" ]; then
    mkdir -p "$(dirname "$QUICK_NOTE_FILE")"
    touch "$QUICK_NOTE_FILE"
fi

# Check if quick-note-nvim window exists
if ! quick_note_running; then
    # Not running — start it in the background
    kitty --class="$QUICK_NOTE_CLASS" -e nvim "$QUICK_NOTE_FILE" &
    # Wait for the window to register with Hyprland (up to 3 seconds)
    for i in $(seq 1 30); do
        if quick_note_running; then break; fi
        sleep 0.1
    done
fi

# Toggle the special workspace
hyprctl dispatch togglespecialworkspace quick-note

# Focus the window after toggling
sleep 0.05
hyprctl dispatch focuswindow "class:^($QUICK_NOTE_CLASS)$"
