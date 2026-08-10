#!/usr/bin/env bash
notif="$HOME/.config/swaync/images/bell.png"

LAYOUT=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

# `hyprctl keyword` (including its bind/unbind forms) does not work against a
# Lua config; `hyprctl eval` runs hl.* directly instead.
case $LAYOUT in
"master")
	hyprctl eval 'hl.config({ general = { layout = "dwindle" } })'
	hyprctl eval 'hl.bind("SUPER + O", hl.dsp.layout("togglesplit"))'
  notify-send -e -u low -i "$notif" "Dwindle Layout"
	;;
"dwindle")
	hyprctl eval 'hl.config({ general = { layout = "master" } })'
	hyprctl eval 'hl.unbind("SUPER + O")'
  notify-send -e -u low -i "$notif" "Master Layout"
	;;
*) ;;

esac
