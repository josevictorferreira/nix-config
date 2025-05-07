#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##

# For Hyprlock

pidof hyprlock || hyprlock -c $XDG_CONFIG_HOME/hypr/hyprlock-2k.conf -q 
