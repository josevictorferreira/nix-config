#!/usr/bin/env bash

function random_hex() {
    random_hex=("0xff$(openssl rand -hex 3)")
    echo $random_hex
}

# `hyprctl keyword` does not work against a Lua config. A gradient is a table
# with a "colors" array plus an angle, so build the ten stops as a Lua list.
function gradient_stops() {
    local stops=""
    for _ in $(seq 1 10); do
        stops="${stops}${stops:+, }\"$(random_hex)\""
    done
    echo "$stops"
}

# rainbow colors only for active window
hyprctl eval "hl.config({ general = { col = { active_border = { colors = { $(gradient_stops) }, angle = 270 } } } })"

# rainbow colors for inactive window (uncomment to take effect)
#hyprctl eval "hl.config({ general = { col = { inactive_border = { colors = { $(gradient_stops) }, angle = 270 } } } })"