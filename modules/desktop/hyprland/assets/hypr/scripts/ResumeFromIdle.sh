#!/usr/bin/env bash

set -e

hyprctl dispatch 'hl.dsp.dpms("on")'

if [[ "$HOSTNAME" == *"desktop" ]]; then
  sleep 2

  killall -q hyprlock || true

  hyprlock &
fi


bash ~/.config/hypr/scripts/Refresh.sh
