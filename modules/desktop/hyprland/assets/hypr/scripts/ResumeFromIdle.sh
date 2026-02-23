#!/usr/bin/env bash

set -e

hyprctl dispatch dpms on

if [[ "$HOSTNAME" == *"desktop" ]]; then
  sleep 2

  killall -q hyprlock || true

  hyprlock &
fi


bash ~/.config/hypr/scripts/Refresh.sh
