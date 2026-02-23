#!/usr/bin/env bash

polkit_gnome_paths=$(find /nix/store -name 'polkit-gnome-authentication-agent-1' -type f 2>/dev/null)

for polkit_gnome_path in $polkit_gnome_paths; do
  polkit_gnome_dir=$(dirname "$polkit_gnome_path")

  if [ -x "$polkit_gnome_dir/polkit-gnome-authentication-agent-1" ]; then
    "$polkit_gnome_dir/polkit-gnome-authentication-agent-1" &
    exit 0
  fi
done

echo "No valid Polkit-GNOME Authentication Agent executable found."