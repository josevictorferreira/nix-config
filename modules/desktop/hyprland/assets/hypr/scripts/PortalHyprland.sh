#!/bin/bash
# Restart xdg-desktop-portal for Hyprland
# NixOS-compatible: discovers binaries via PATH instead of hardcoded FHS paths

sleep 1
killall xdg-desktop-portal-hyprland 2>/dev/null
killall xdg-desktop-portal-wlr 2>/dev/null
killall xdg-desktop-portal-gnome 2>/dev/null
killall xdg-desktop-portal 2>/dev/null
sleep 1

# Find and launch portal backends via PATH (NixOS puts them in /run/current-system/sw/libexec/)
for dir in /run/current-system/sw/libexec /run/current-system/sw/lib; do
  if [ -x "$dir/xdg-desktop-portal-hyprland" ]; then
    "$dir/xdg-desktop-portal-hyprland" &
    break
  fi
done

sleep 2

for dir in /run/current-system/sw/libexec /run/current-system/sw/lib; do
  if [ -x "$dir/xdg-desktop-portal" ]; then
    "$dir/xdg-desktop-portal" &
    break
  fi
done
