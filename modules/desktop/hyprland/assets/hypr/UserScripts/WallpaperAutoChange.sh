#!/usr/bin/env bash

if [[ $# -lt 1 ]] || [[ ! -d $1   ]]; then
	echo "Usage:
	$0 <dir containing images>"
	exit 1
fi

# Edit below to control the images transition
export SWWW_TRANSITION_FPS=60
export SWWW_TRANSITION_TYPE=simple

# This controls (in seconds) when to switch to the next image
INTERVAL=1800

while true; do
	find "$1" \
		| while read -r img; do
			echo "$((RANDOM % 1000)):$img"
		done \
		| sort -n | cut -d':' -f2- \
		| while read -r img; do
			# Apply wallpaper to all monitors
			for monitor in $(hyprctl monitors -j | jq -r '.[].name'); do
				awww img -o "$monitor" "$img" &
			done
			wait
			$HOME/.config/hypr/scripts/RefreshNoWaybar.sh
			sleep $INTERVAL
			
		done
done
