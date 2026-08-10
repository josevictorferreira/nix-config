#!/usr/bin/env bash
notif="$HOME/.config/swaync/images/bell.png"

STATE=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

# `hyprctl keyword` does not work against a Lua config ("keyword can't work with
# non-legacy parsers. Use eval."). Colon paths become nested tables.
if [ "${STATE}" == "2" ]; then
	hyprctl eval 'hl.config({ decoration = { blur = { size = 2, passes = 1 } } })'
 	notify-send -e -u low -i "$notif" "Less blur"
else
	hyprctl eval 'hl.config({ decoration = { blur = { size = 5, passes = 2 } } })'
  	notify-send -e -u low -i "$notif" "Normal blur"
fi
